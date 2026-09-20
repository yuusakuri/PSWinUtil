using System;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;

namespace PSWinUtil
{
    public sealed class NativeCommandResult
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

        public NativeCommandResult(bool succeeded, int exitCode, string standardOutput, string standardError)
        {
            Succeeded = succeeded;
            ExitCode = exitCode;
            StandardOutput = standardOutput ?? string.Empty;
            StandardError = standardError ?? string.Empty;
        }

        public string Message()
        {
            if (StandardError.Length == 0)
            {
                return StandardOutput;
            }
            if (StandardOutput.Length == 0)
            {
                return StandardError;
            }

            bool hasBoundaryNewline = StandardError.EndsWith("\n", StringComparison.Ordinal) ||
                StandardError.EndsWith("\r", StringComparison.Ordinal) ||
                StandardOutput.StartsWith("\n", StringComparison.Ordinal) ||
                StandardOutput.StartsWith("\r", StringComparison.Ordinal);
            return StandardError + (hasBoundaryNewline ? string.Empty : Environment.NewLine) + StandardOutput;
        }

        public string ToDebugString()
        {
            var serializer = new DataContractJsonSerializer(typeof(DebugResult));
            using (var stream = new MemoryStream())
            {
                serializer.WriteObject(stream, new DebugResult { ExitCode = ExitCode, Message = Message() });
                return Encoding.UTF8.GetString(stream.ToArray());
            }
        }
    }
}
