namespace PSWinUtil.NativeMethods
{
    using System;
    using System.Runtime.InteropServices;

    /// <summary>
    /// Declares the advapi32.dll entry points that manage Local Security Authority private data.
    /// </summary>
    public static class LsaPolicy
    {
        /// <summary>
        /// Opens a handle to the Local Security Authority policy object.
        /// </summary>
        /// <param name="systemName">The target system. A null pointer selects the local system.</param>
        /// <param name="objectAttributes">The object attributes. The API requires the structure size only.</param>
        /// <param name="desiredAccess">The requested access mask.</param>
        /// <param name="policyHandle">Receives the policy handle.</param>
        /// <returns>An NTSTATUS value.</returns>
        [DllImport("advapi32.dll")]
        public static extern uint LsaOpenPolicy(
            IntPtr systemName,
            ref LsaObjectAttributes objectAttributes,
            uint desiredAccess,
            out IntPtr policyHandle);

        /// <summary>
        /// Stores a private data secret.
        /// </summary>
        /// <param name="policyHandle">The policy handle.</param>
        /// <param name="keyName">The secret name.</param>
        /// <param name="privateData">The secret value.</param>
        /// <returns>An NTSTATUS value.</returns>
        [DllImport("advapi32.dll", EntryPoint = "LsaStorePrivateData")]
        public static extern uint LsaStorePrivateDataValue(
            IntPtr policyHandle,
            ref LsaUnicodeString keyName,
            ref LsaUnicodeString privateData);

        /// <summary>
        /// Deletes a private data secret.
        /// </summary>
        /// <param name="policyHandle">The policy handle.</param>
        /// <param name="keyName">The secret name.</param>
        /// <param name="privateData">A null pointer that requests deletion.</param>
        /// <returns>An NTSTATUS value.</returns>
        [DllImport("advapi32.dll", EntryPoint = "LsaStorePrivateData")]
        public static extern uint LsaStorePrivateDataDelete(
            IntPtr policyHandle,
            ref LsaUnicodeString keyName,
            IntPtr privateData);

        /// <summary>
        /// Closes a policy handle.
        /// </summary>
        /// <param name="policyHandle">The policy handle.</param>
        /// <returns>An NTSTATUS value.</returns>
        [DllImport("advapi32.dll")]
        public static extern uint LsaClose(IntPtr policyHandle);

        /// <summary>
        /// Converts an NTSTATUS value into a Windows error code.
        /// </summary>
        /// <param name="status">The NTSTATUS value.</param>
        /// <returns>A Windows error code.</returns>
        [DllImport("advapi32.dll")]
        public static extern uint LsaNtStatusToWinError(uint status);
    }
}
