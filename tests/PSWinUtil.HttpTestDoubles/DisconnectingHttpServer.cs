namespace PSWinUtil.Tests
{
    using System;
    using System.Collections.Generic;
    using System.Globalization;
    using System.IO;
    using System.Net;
    using System.Net.Sockets;
    using System.Text;
    using System.Threading;

    /// <summary>
    /// Serves a byte array and closes selected responses before their declared length.
    /// </summary>
    public sealed class DisconnectingHttpServer : IDisposable
    {
        private readonly byte[] body;
        private readonly int[] responseByteCounts;
        private readonly TcpListener listener;
        private readonly Thread serverThread;
        private readonly object syncRoot = new object();
        private readonly List<long> rangeStarts = new List<long>();
        private volatile bool stopping;

        /// <summary>
        /// Initializes and starts a local HTTP server.
        /// </summary>
        /// <param name="body">The complete response body.</param>
        /// <param name="responseByteCounts">
        /// The maximum body bytes sent by each request. Requests beyond the array receive all remaining bytes.
        /// </param>
        public DisconnectingHttpServer(byte[] body, int[] responseByteCounts)
        {
            this.body = body ?? throw new ArgumentNullException(nameof(body));
            this.responseByteCounts = responseByteCounts ?? throw new ArgumentNullException(nameof(responseByteCounts));
            this.listener = new TcpListener(IPAddress.Loopback, 0);
            this.listener.Start();
            var endpoint = (IPEndPoint)this.listener.LocalEndpoint;
            this.Uri = new Uri(
                string.Format(
                    CultureInfo.InvariantCulture,
                    "http://127.0.0.1:{0}/package.zip",
                    endpoint.Port));
            this.serverThread = new Thread(this.Run)
            {
                IsBackground = true,
                Name = "PSWinUtil test HTTP server",
            };
            this.serverThread.Start();
        }

        /// <summary>
        /// Gets the HTTP endpoint.
        /// </summary>
        public Uri Uri { get; }

        /// <summary>
        /// Gets the range start for each request. Minus one represents a request without a Range header.
        /// </summary>
        public long[] RangeStarts
        {
            get
            {
                lock (this.syncRoot)
                {
                    return this.rangeStarts.ToArray();
                }
            }
        }

        /// <summary>
        /// Gets an unexpected server exception.
        /// </summary>
        public Exception ServerException { get; private set; }

        /// <inheritdoc/>
        public void Dispose()
        {
            this.stopping = true;
            this.listener.Stop();
            this.serverThread.Join(TimeSpan.FromSeconds(5));
        }

        private void Run()
        {
            var requestIndex = 0;
            try
            {
                while (!this.stopping)
                {
                    TcpClient client;
                    try
                    {
                        client = this.listener.AcceptTcpClient();
                    }
                    catch (SocketException) when (this.stopping)
                    {
                        break;
                    }
                    catch (ObjectDisposedException) when (this.stopping)
                    {
                        break;
                    }

                    using (client)
                    {
                        var stream = client.GetStream();
                        var headers = ReadHeaders(stream);
                        var rangeStart = ParseRangeStart(headers);
                        lock (this.syncRoot)
                        {
                            this.rangeStarts.Add(rangeStart);
                        }

                        var bodyStart = rangeStart < 0 ? 0 : checked((int)rangeStart);
                        if (bodyStart > this.body.Length)
                        {
                            WriteHeaders(stream, "416 Range Not Satisfiable", 0, null);
                            requestIndex++;
                            continue;
                        }

                        var remainingLength = this.body.Length - bodyStart;
                        var bytesToSend = remainingLength;
                        if (requestIndex < this.responseByteCounts.Length)
                        {
                            bytesToSend = Math.Min(
                                remainingLength,
                                Math.Max(0, this.responseByteCounts[requestIndex]));
                        }

                        var status = rangeStart < 0 ? "200 OK" : "206 Partial Content";
                        var contentRange = rangeStart < 0
                            ? null
                            : string.Format(
                                CultureInfo.InvariantCulture,
                                "bytes {0}-{1}/{2}",
                                bodyStart,
                                this.body.Length - 1,
                                this.body.Length);
                        WriteHeaders(stream, status, remainingLength, contentRange);
                        if (bytesToSend > 0)
                        {
                            stream.Write(this.body, bodyStart, bytesToSend);
                            stream.Flush();
                        }
                        requestIndex++;
                    }
                }
            }
            catch (Exception exception)
            {
                if (!this.stopping)
                {
                    this.ServerException = exception;
                }
            }
        }

        private static string ReadHeaders(Stream stream)
        {
            var bytes = new List<byte>();
            while (bytes.Count < 65536)
            {
                var value = stream.ReadByte();
                if (value < 0)
                {
                    throw new EndOfStreamException("The HTTP request ended before its headers were complete.");
                }
                bytes.Add((byte)value);
                var count = bytes.Count;
                if (
                    count >= 4 &&
                    bytes[count - 4] == 13 &&
                    bytes[count - 3] == 10 &&
                    bytes[count - 2] == 13 &&
                    bytes[count - 1] == 10)
                {
                    return Encoding.ASCII.GetString(bytes.ToArray());
                }
            }

            throw new InvalidDataException("The HTTP request headers exceeded the test limit.");
        }

        private static long ParseRangeStart(string headers)
        {
            foreach (var line in headers.Split(new[] { "\r\n" }, StringSplitOptions.None))
            {
                const string prefix = "Range: bytes=";
                if (line.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                {
                    var value = line.Substring(prefix.Length);
                    var separator = value.IndexOf('-');
                    if (separator >= 0)
                    {
                        value = value.Substring(0, separator);
                    }
                    return long.Parse(value, CultureInfo.InvariantCulture);
                }
            }

            return -1;
        }

        private static void WriteHeaders(
            Stream stream,
            string status,
            int contentLength,
            string contentRange)
        {
            var builder = new StringBuilder();
            builder.Append("HTTP/1.1 ").Append(status).Append("\r\n");
            builder.Append("Content-Type: application/octet-stream\r\n");
            builder.Append("Accept-Ranges: bytes\r\n");
            builder.Append("Content-Length: ")
                .Append(contentLength.ToString(CultureInfo.InvariantCulture))
                .Append("\r\n");
            if (contentRange != null)
            {
                builder.Append("Content-Range: ").Append(contentRange).Append("\r\n");
            }
            builder.Append("Connection: close\r\n\r\n");
            var bytes = Encoding.ASCII.GetBytes(builder.ToString());
            stream.Write(bytes, 0, bytes.Length);
            stream.Flush();
        }
    }
}
