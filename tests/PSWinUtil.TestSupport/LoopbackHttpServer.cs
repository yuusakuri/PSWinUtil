namespace PSWinUtil.Tests
{
    using System;
    using System.IO;
    using System.Globalization;
    using System.Net;
    using System.Net.Sockets;
    using System.Text;
    using System.Threading.Tasks;

    /// <summary>Serves controlled HTTP responses over real loopback sockets.</summary>
    public sealed class LoopbackHttpServer : IDisposable
    {
        private readonly TcpListener listener;
        private readonly Task worker;
        private readonly byte[] body;

        /// <summary>Starts an isolated server on an OS-assigned port.</summary>
        public LoopbackHttpServer(byte[] body)
        {
            this.body = body;
            this.listener = new TcpListener(IPAddress.Loopback, 0);
            this.listener.Start();
            this.BaseUri = new Uri("http://127.0.0.1:" + ((IPEndPoint)this.listener.LocalEndpoint).Port + "/");
            this.worker = Task.Run(() => this.Serve());
        }

        /// <summary>Gets the server address.</summary>
        public Uri BaseUri { get; }

        /// <inheritdoc/>
        public void Dispose()
        {
            this.listener.Stop();
            this.worker.GetAwaiter().GetResult();
        }

        private void Serve()
        {
            while (true)
            {
                TcpClient client;
                try
                {
                    client = this.listener.AcceptTcpClient();
                }
                catch (SocketException)
                {
                    return;
                }
                catch (ObjectDisposedException)
                {
                    return;
                }

                using (client)
                {
                    client.ReceiveTimeout = 5000;
                    using (var stream = client.GetStream())
                    using (var reader = new StreamReader(stream, Encoding.ASCII, false, 1024, true))
                    {
                        var request = reader.ReadLine() ?? string.Empty;
                        var offset = 0L;
                        string line;
                        while (!string.IsNullOrEmpty(line = reader.ReadLine()))
                        {
                            if (line.StartsWith("Range: bytes=", StringComparison.OrdinalIgnoreCase))
                            {
                                offset = long.Parse(line.Substring(13).TrimEnd('-'), CultureInfo.InvariantCulture);
                            }
                        }

                        var failure = request.Contains("/fail ");
                        var invalid = request.Contains("/invalid ");
                        var partial = offset > 0 && !request.Contains("/ignore ") && !failure;
                        if (partial && offset >= this.body.LongLength)
                        {
                            var unsatisfied = Encoding.ASCII.GetBytes("HTTP/1.1 416 Range Not Satisfiable\r\nConnection: close\r\nContent-Length: 0\r\nContent-Range: bytes */" + this.body.LongLength + "\r\n\r\n");
                            stream.Write(unsatisfied, 0, unsatisfied.Length);
                            continue;
                        }

                        var start = partial ? checked((int)offset) : 0;
                        var length = failure ? 0 : this.body.Length - start;
                        var status = failure ? "503 Service Unavailable" : partial ? "206 Partial Content" : "200 OK";
                        var headers = "HTTP/1.1 " + status + "\r\nConnection: close\r\nContent-Length: " + length + "\r\n";
                        if (partial)
                        {
                            headers += "Content-Range: bytes " + (invalid ? 0 : start) + "-" + (this.body.Length - 1) + "/" + this.body.Length + "\r\n";
                        }

                        var bytes = Encoding.ASCII.GetBytes(headers + "\r\n");
                        stream.Write(bytes, 0, bytes.Length);
                        if (request.Contains("/interrupt ") && offset == 0)
                        {
                            length /= 2;
                        }

                        stream.Write(this.body, start, length);
                    }
                }
            }
        }
    }
}
