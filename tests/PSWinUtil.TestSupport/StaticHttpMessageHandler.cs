namespace PSWinUtil.Tests
{
    using System;
    using System.Net;
    using System.Net.Http;
    using System.Threading;
    using System.Threading.Tasks;

    /// <summary>
    /// Returns a fixed response so that download tests never reach the network.
    /// </summary>
    public sealed class StaticHttpMessageHandler : HttpMessageHandler
    {
        private readonly byte[] body;
        private readonly HttpStatusCode statusCode;

        /// <summary>
        /// Initializes a new instance of the <see cref="StaticHttpMessageHandler"/> class.
        /// </summary>
        /// <param name="body">The response body to return.</param>
        /// <param name="statusCode">The status code to return.</param>
        public StaticHttpMessageHandler(byte[] body, HttpStatusCode statusCode)
        {
            this.body = body;
            this.statusCode = statusCode;
        }

        /// <summary>
        /// Gets the request URI of the most recent request.
        /// </summary>
        public Uri RequestUri { get; private set; }

        /// <inheritdoc/>
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            if (request == null)
            {
                throw new ArgumentNullException(nameof(request));
            }

            this.RequestUri = request.RequestUri;
            var response = new HttpResponseMessage(this.statusCode);
            response.Content = new ByteArrayContent(this.body);
            return Task.FromResult(response);
        }
    }
}
