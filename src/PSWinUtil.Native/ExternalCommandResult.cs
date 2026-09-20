using System;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;

namespace PSWinUtil
{
    public sealed class ExternalCommandResult
    {
        [DataContract]
        private sealed class DebugResult
        {
            [DataMember(Name = "exit_code", Order = 0)]
            public int ExitCode { get; set; }

            [DataMember(Name = "message", Order = 1)]
            public string Message { get; set; }
        }

        public bool Succeeded { get; }

        public int ExitCode { get; }

        public string StandardOutput { get; }

        public string StandardError { get; }

        public ExternalCommandResult(bool succeeded, int exitCode, string standardOutput, string standardError)
        {
            Succeeded = succeeded;
            ExitCode = exitCode;
            StandardOutput = standardOutput;
            StandardError = standardError;
        }

        public string ToDebugString()
        {
            string message = StandardError ?? string.Empty;
            if (!string.IsNullOrEmpty(StandardOutput))
            {
                if (message.Length == 0)
                {
                    message = StandardOutput;
                }
                else
                {
                    string separator = StandardError.EndsWith("\n", StringComparison.Ordinal) ||
                        StandardOutput.StartsWith("\n", StringComparison.Ordinal)
                        ? string.Empty
                        : Environment.NewLine;
                    message = StandardError + separator + StandardOutput;
                }
            }

            var serializer = new DataContractJsonSerializer(typeof(DebugResult));
            using (var stream = new MemoryStream())
            {
                serializer.WriteObject(stream, new DebugResult { ExitCode = ExitCode, Message = message });
                return Encoding.UTF8.GetString(stream.ToArray());
            }
        }
    }
}
