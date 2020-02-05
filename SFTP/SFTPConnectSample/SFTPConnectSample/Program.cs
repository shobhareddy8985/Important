using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Tamir.SharpSsh;
using System.Collections;
using System.Windows.Forms;
using System.IO;
using Tamir.SharpSsh.jsch;
namespace SFTPConnectSample
{
    class Program
    {
        static void Main(string[] args)
        {
            Sftp sftp = new Sftp(SFTPConnectSample.Properties.Settings.Default.HostName, SFTPConnectSample.Properties.Settings.Default.UserName, SFTPConnectSample.Properties.Settings.Default.Password);

            sftp.Connect();
            #region Require if you want to delete Files
            JSch objjsh = new JSch();
            Session session = objjsh.getSession(SFTPConnectSample.Properties.Settings.Default.UserName, SFTPConnectSample.Properties.Settings.Default.HostName);
            // Get a UserInfo object
            UserInfo ui = new UInfo(SFTPConnectSample.Properties.Settings.Default.Password); ;
            // Pass user info to session
            session.setUserInfo(ui);
            // Open the session
            session.connect();
            Channel channel = session.openChannel("sftp");
            ChannelSftp cSftp = (ChannelSftp)channel;
            cSftp.connect();
            #endregion
            ArrayList res = sftp.GetFileList(SFTPConnectSample.Properties.Settings.Default.FromPath + "*.xml");
            foreach (var item in res)
            {
                if (item.ToString() != "." && item.ToString() != "..")
                {
                    //File Copy from Remote
                    sftp.Get(SFTPConnectSample.Properties.Settings.Default.FromPath + item, Path.Combine(Application.StartupPath, SFTPConnectSample.Properties.Settings.Default.DirectoryPath + "/" + item));
                    //File Delete from Remote
                    cSftp.rm(SFTPConnectSample.Properties.Settings.Default.FromPath + item);
                    //Upload File
                    sftp.Put(Path.Combine(Path.Combine(Application.StartupPath, "XMLFiles"), item.ToString()), SFTPConnectSample.Properties.Settings.Default.ToPath + item);
                }

            }
            channel.disconnect();
            cSftp.exit();
            sftp.Close();
       


        }
    }
    public class UInfo : UserInfo
    {

        string _passwd = string.Empty;

        public UInfo() { _passwd = string.Empty; }

        public UInfo(string pwd) { _passwd = pwd; }

        public String getPassword() { return _passwd; }

        public string Password
        {

            set { _passwd = value; }

            get { return _passwd; }

        }

        #region Dummy Implementations

        public bool promptYesNo(String str) { return true; }

        public String getPassphrase() { return null; }

        public bool promptPassphrase(String message) { return true; }

        public bool promptPassword(String message) { return true; }

        public void showMessage(String message) { }

        #endregion Dummy Implementations

    }
}
