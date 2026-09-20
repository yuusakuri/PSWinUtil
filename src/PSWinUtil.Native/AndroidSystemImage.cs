using System;

namespace PSWinUtil
{
    public sealed class AndroidSystemImage
    {
        public int PlatformVersion { get; }

        public string SystemImageTag { get; }

        public string Abi { get; }

        public string Version { get; }

        public AndroidSystemImage(int platformVersion, string systemImageTag, string abi, string version)
        {
            PlatformVersion = platformVersion;
            SystemImageTag = systemImageTag ?? throw new ArgumentNullException(nameof(systemImageTag));
            Abi = abi ?? throw new ArgumentNullException(nameof(abi));
            Version = version ?? throw new ArgumentNullException(nameof(version));
        }
    }
}
