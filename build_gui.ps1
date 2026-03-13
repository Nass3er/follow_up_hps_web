$targetDir = "D:\TestAppsAsp.net-Core-api\HpsLicenseManager\HpsLicenseManager"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path "$targetDir\Models"
New-Item -ItemType Directory -Force -Path "$targetDir\Services"

# 1. Models/AppLicense.cs
$AppLicenseCode = @"
using System;

namespace HpsLicenseManager.Models
{
    public class AppLicense
    {
        public string CustomerNo { get; set; }
        public string CustomerName { get; set; }
        public string MachineName { get; set; }
        public DateTime ExpiryDate { get; set; }
        public int MaxDevices { get; set; }
        public string SystemNo { get; set; }
        public string BranchNo { get; set; }
    }
}
"@
Set-Content -Path "$targetDir\Models\AppLicense.cs" -Value $AppLicenseCode -Encoding UTF8

# 2. Models/ClientRecord.cs
$ClientRecordCode = @"
using System;

namespace HpsLicenseManager.Models
{
    public class ClientRecord
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string CustomerNo { get; set; }
        public string CustomerName { get; set; }
        public string MachineName { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime ExpiryDate { get; set; }
        public int MaxDevices { get; set; }
        public string BranchNo { get; set; }
        public string SystemNo { get; set; }
    }
}
"@
Set-Content -Path "$targetDir\Models\ClientRecord.cs" -Value $ClientRecordCode -Encoding UTF8

# 3. Services/CryptoService.cs
$CryptoServiceCode = @"
using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace HpsLicenseManager.Services
{
    public static class CryptoService
    {
        private static readonly byte[] Key = Encoding.UTF8.GetBytes("HPS@N@SS3R#2026`$SECRET!KEY_PROD-").Take(32).ToArray();
        private static readonly byte[] IV = Encoding.UTF8.GetBytes("HPS@N@SS3R#2026`$").Take(16).ToArray();

        public static byte[] Encrypt(string plainText)
        {
            using Aes aes = Aes.Create();
            aes.Key = Key;
            aes.IV = IV;
            using ICryptoTransform encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
            using MemoryStream ms = new MemoryStream();
            using CryptoStream cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write);
            using StreamWriter sw = new StreamWriter(cs);
            sw.Write(plainText);
            sw.Flush();
            cs.FlushFinalBlock();
            return ms.ToArray();
        }
    }
}
"@
Set-Content -Path "$targetDir\Services\CryptoService.cs" -Value $CryptoServiceCode -Encoding UTF8

# 4. Services/DatabaseService.cs
$DatabaseServiceCode = @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using HpsLicenseManager.Models;

namespace HpsLicenseManager.Services
{
    public class DatabaseService
    {
        private readonly string _dbPath;

        public DatabaseService()
        {
            _dbPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "clients_db.json");
            if (!File.Exists(_dbPath))
            {
                File.WriteAllText(_dbPath, "[]");
            }
        }

        public List<ClientRecord> GetAllClients()
        {
            var json = File.ReadAllText(_dbPath);
            return JsonSerializer.Deserialize<List<ClientRecord>>(json) ?? new List<ClientRecord>();
        }

        public void SaveClient(ClientRecord newClient)
        {
            var clients = GetAllClients();
            var existing = clients.Find(c => c.CustomerNo == newClient.CustomerNo && c.MachineName == newClient.MachineName);
            if (existing != null)
            {
                existing.CustomerName = newClient.CustomerName;
                existing.ExpiryDate = newClient.ExpiryDate;
                existing.MaxDevices = newClient.MaxDevices;
            }
            else
            {
                clients.Add(newClient);
            }

            var json = JsonSerializer.Serialize(clients, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_dbPath, json);
        }

        public void DeleteClient(string id)
        {
            var clients = GetAllClients();
            clients.RemoveAll(c => c.Id == id);
            var json = JsonSerializer.Serialize(clients, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_dbPath, json);
        }
    }
}
"@
Set-Content -Path "$targetDir\Services\DatabaseService.cs" -Value $DatabaseServiceCode -Encoding UTF8

# 5. Form1.Designer.cs
$Form1DesignerCode = @"
namespace HpsLicenseManager
{
    partial class Form1
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            this.btnImport = new System.Windows.Forms.Button();
            this.txtCustomerNo = new System.Windows.Forms.TextBox();
            this.txtBranch = new System.Windows.Forms.TextBox();
            this.txtSystemVal = new System.Windows.Forms.TextBox();
            this.txtMachineName = new System.Windows.Forms.TextBox();
            this.txtCustomerName = new System.Windows.Forms.TextBox();
            this.dtpExpiry = new System.Windows.Forms.DateTimePicker();
            this.numMaxDevices = new System.Windows.Forms.NumericUpDown();
            this.btnGenerate = new System.Windows.Forms.Button();
            this.dgvClients = new System.Windows.Forms.DataGridView();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.label5 = new System.Windows.Forms.Label();
            this.label6 = new System.Windows.Forms.Label();
            this.label7 = new System.Windows.Forms.Label();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            ((System.ComponentModel.ISupportInitialize)(this.numMaxDevices)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dgvClients)).BeginInit();
            this.groupBox1.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.SuspendLayout();
            // 
            // btnImport
            // 
            this.btnImport.Location = new System.Drawing.Point(20, 30);
            this.btnImport.Name = "btnImport";
            this.btnImport.Size = new System.Drawing.Size(160, 40);
            this.btnImport.TabIndex = 0;
            this.btnImport.Text = "استيراد ملف YS_KEY.txt";
            this.btnImport.UseVisualStyleBackColor = true;
            this.btnImport.Click += new System.EventHandler(this.btnImport_Click);
            // 
            // txtCustomerNo
            // 
            this.txtCustomerNo.Location = new System.Drawing.Point(120, 80);
            this.txtCustomerNo.Name = "txtCustomerNo";
            this.txtCustomerNo.ReadOnly = true;
            this.txtCustomerNo.Size = new System.Drawing.Size(150, 23);
            this.txtCustomerNo.TabIndex = 1;
            // 
            // txtBranch
            // 
            this.txtBranch.Location = new System.Drawing.Point(120, 110);
            this.txtBranch.Name = "txtBranch";
            this.txtBranch.ReadOnly = true;
            this.txtBranch.Size = new System.Drawing.Size(150, 23);
            this.txtBranch.TabIndex = 2;
            // 
            // txtSystemVal
            // 
            this.txtSystemVal.Location = new System.Drawing.Point(120, 140);
            this.txtSystemVal.Name = "txtSystemVal";
            this.txtSystemVal.ReadOnly = true;
            this.txtSystemVal.Size = new System.Drawing.Size(150, 23);
            this.txtSystemVal.TabIndex = 3;
            // 
            // txtMachineName
            // 
            this.txtMachineName.Location = new System.Drawing.Point(120, 170);
            this.txtMachineName.Name = "txtMachineName";
            this.txtMachineName.ReadOnly = true;
            this.txtMachineName.Size = new System.Drawing.Size(250, 23);
            this.txtMachineName.TabIndex = 4;
            // 
            // txtCustomerName
            // 
            this.txtCustomerName.Location = new System.Drawing.Point(120, 30);
            this.txtCustomerName.Name = "txtCustomerName";
            this.txtCustomerName.Size = new System.Drawing.Size(250, 23);
            this.txtCustomerName.TabIndex = 5;
            // 
            // dtpExpiry
            // 
            this.dtpExpiry.Location = new System.Drawing.Point(120, 60);
            this.dtpExpiry.Name = "dtpExpiry";
            this.dtpExpiry.Size = new System.Drawing.Size(250, 23);
            this.dtpExpiry.TabIndex = 6;
            // 
            // numMaxDevices
            // 
            this.numMaxDevices.Location = new System.Drawing.Point(120, 90);
            this.numMaxDevices.Name = "numMaxDevices";
            this.numMaxDevices.Size = new System.Drawing.Size(120, 23);
            this.numMaxDevices.TabIndex = 7;
            this.numMaxDevices.Value = new decimal(new int[] {
            10,
            0,
            0,
            0});
            // 
            // btnGenerate
            // 
            this.btnGenerate.BackColor = System.Drawing.Color.MediumSeaGreen;
            this.btnGenerate.ForeColor = System.Drawing.Color.White;
            this.btnGenerate.Location = new System.Drawing.Point(120, 130);
            this.btnGenerate.Name = "btnGenerate";
            this.btnGenerate.Size = new System.Drawing.Size(250, 45);
            this.btnGenerate.TabIndex = 8;
            this.btnGenerate.Text = "إنشاء التفعيل (license.rar)";
            this.btnGenerate.UseVisualStyleBackColor = false;
            this.btnGenerate.Click += new System.EventHandler(this.btnGenerate_Click);
            // 
            // dgvClients
            // 
            this.dgvClients.AllowUserToAddRows = false;
            this.dgvClients.AutoSizeColumnsMode = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill;
            this.dgvClients.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvClients.Location = new System.Drawing.Point(20, 260);
            this.dgvClients.Name = "dgvClients";
            this.dgvClients.ReadOnly = true;
            this.dgvClients.RowTemplate.Height = 25;
            this.dgvClients.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.dgvClients.Size = new System.Drawing.Size(840, 280);
            this.dgvClients.TabIndex = 9;
            this.dgvClients.CellDoubleClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvClients_CellDoubleClick);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(20, 83);
            this.label1.Name = "label1";
            this.label1.Text = "رقم العميل:";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(20, 113);
            this.label2.Name = "label2";
            this.label2.Text = "الفرع:";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(20, 143);
            this.label3.Name = "label3";
            this.label3.Text = "النظام:";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(20, 173);
            this.label4.Name = "label4";
            this.label4.Text = "اسم السيرفر:";
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(20, 33);
            this.label5.Name = "label5";
            this.label5.Text = "اسم المستشفى:";
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(20, 66);
            this.label6.Name = "label6";
            this.label6.Text = "تاريخ الانتهاء:";
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(20, 92);
            this.label7.Name = "label7";
            this.label7.Text = "أجهزة الهاتف المسموحة:";
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.btnImport);
            this.groupBox1.Controls.Add(this.txtCustomerNo);
            this.groupBox1.Controls.Add(this.label1);
            this.groupBox1.Controls.Add(this.txtBranch);
            this.groupBox1.Controls.Add(this.label2);
            this.groupBox1.Controls.Add(this.txtSystemVal);
            this.groupBox1.Controls.Add(this.label3);
            this.groupBox1.Controls.Add(this.txtMachineName);
            this.groupBox1.Controls.Add(this.label4);
            this.groupBox1.Location = new System.Drawing.Point(20, 20);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(400, 220);
            this.groupBox1.TabIndex = 10;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "بيانات ملف الترخيص المسحوب";
            // 
            // groupBox2
            // 
            this.groupBox2.Controls.Add(this.txtCustomerName);
            this.groupBox2.Controls.Add(this.label5);
            this.groupBox2.Controls.Add(this.dtpExpiry);
            this.groupBox2.Controls.Add(this.label6);
            this.groupBox2.Controls.Add(this.numMaxDevices);
            this.groupBox2.Controls.Add(this.btnGenerate);
            this.groupBox2.Controls.Add(this.label7);
            this.groupBox2.Location = new System.Drawing.Point(440, 20);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(420, 220);
            this.groupBox2.TabIndex = 11;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "إعدادات التفعيل";
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(884, 561);
            this.Controls.Add(this.groupBox2);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.dgvClients);
            this.Name = "Form1";
            this.RightToLeft = System.Windows.Forms.RightToLeft.Yes;
            this.RightToLeftLayout = true;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "نظام إدارة تراخيص HPS (المطور)";
            this.Load += new System.EventHandler(this.Form1_Load);
            ((System.ComponentModel.ISupportInitialize)(this.numMaxDevices)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dgvClients)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.groupBox2.ResumeLayout(false);
            this.groupBox2.PerformLayout();
            this.ResumeLayout(false);

        }

        private System.Windows.Forms.Button btnImport;
        private System.Windows.Forms.TextBox txtCustomerNo;
        private System.Windows.Forms.TextBox txtBranch;
        private System.Windows.Forms.TextBox txtSystemVal;
        private System.Windows.Forms.TextBox txtMachineName;
        private System.Windows.Forms.TextBox txtCustomerName;
        private System.Windows.Forms.DateTimePicker dtpExpiry;
        private System.Windows.Forms.NumericUpDown numMaxDevices;
        private System.Windows.Forms.Button btnGenerate;
        private System.Windows.Forms.DataGridView dgvClients;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.GroupBox groupBox2;
    }
}
"@
Set-Content -Path "$targetDir\Form1.Designer.cs" -Value $Form1DesignerCode -Encoding UTF8

# 6. Form1.cs
$Form1Code = @"
using HpsLicenseManager.Models;
using HpsLicenseManager.Services;
using System;
using System.IO;
using System.Text.Json;
using System.Windows.Forms;

namespace HpsLicenseManager
{
    public partial class Form1 : Form
    {
        private readonly DatabaseService _dbService;

        public Form1()
        {
            InitializeComponent();
            _dbService = new DatabaseService();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            dtpExpiry.Value = DateTime.Now.AddYears(1);
            LoadClients();
        }

        private void LoadClients()
        {
            dgvClients.DataSource = null;
            var clients = _dbService.GetAllClients();
            dgvClients.DataSource = clients;
            
            if (dgvClients.Columns["Id"] != null)
                dgvClients.Columns["Id"].Visible = false;
        }

        private void btnImport_Click(object sender, EventArgs e)
        {
            using (OpenFileDialog ofd = new OpenFileDialog())
            {
                ofd.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*";
                ofd.Title = "اختر ملف الترخيص المسحوب من العميل (YS_KEY.txt)";
                
                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        var lines = File.ReadAllLines(ofd.FileName);
                        if (lines.Length < 2)
                        {
                            MessageBox.Show("الملف غير صالح أو ناقص.", "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                            return;
                        }

                        // Parse Line 1: 1234501776 (Customer 5, Branch 2, System 3)
                        string line1 = lines[0].Trim();
                        if (line1.Length >= 10)
                        {
                            txtCustomerNo.Text = line1.Substring(0, 5);
                            txtBranch.Text = line1.Substring(5, 2);
                            txtSystemVal.Text = line1.Substring(7, 3);
                        }

                        // Parse Line 2: Ver 2 + DESKTOP-3TDHN3C-Server =QTfP...
                        string line2 = lines[1].Trim();
                        string[] parts = line2.Split(new[] { '+' }, StringSplitOptions.RemoveEmptyEntries);
                        if (parts.Length > 1)
                        {
                            string secondPart = parts[1].Trim();
                            string[] subParts = secondPart.Split('=');
                            if (subParts.Length > 0)
                            {
                                txtMachineName.Text = subParts[0].Trim();
                            }
                        }

                        MessageBox.Show("تم تحميل بيانات الملف بنجاح.", "نجاح", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        
                        // Check if exists in DB to prepopulate
                        var clients = _dbService.GetAllClients();
                        var existing = clients.Find(c => c.CustomerNo == txtCustomerNo.Text && c.MachineName == txtMachineName.Text);
                        if (existing != null)
                        {
                            txtCustomerName.Text = existing.CustomerName;
                            dtpExpiry.Value = existing.ExpiryDate;
                            numMaxDevices.Value = existing.MaxDevices;
                            MessageBox.Show("هذا العميل موجود مسبقاً في قاعدة البيانات، تم تحميل بياناته.", "تنبيه", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("حدث خطأ أثناء قراءة الملف: " + ex.Message, "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void btnGenerate_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtMachineName.Text) || string.IsNullOrEmpty(txtCustomerNo.Text))
            {
                MessageBox.Show("يرجى استيراد ملف YS_KEY.txt أولاً.", "تنبيه", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (string.IsNullOrWhiteSpace(txtCustomerName.Text))
            {
                MessageBox.Show("يرجى إدخال اسم المستشفى/العميل.", "تنبيه", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                // Create License Model
                var license = new AppLicense
                {
                    CustomerNo = txtCustomerNo.Text,
                    CustomerName = txtCustomerName.Text,
                    MachineName = txtMachineName.Text,
                    ExpiryDate = dtpExpiry.Value.Date.AddDays(1).AddSeconds(-1), // End of the day
                    MaxDevices = (int)numMaxDevices.Value,
                    SystemNo = txtSystemVal.Text,
                    BranchNo = txtBranch.Text
                };

                // Serialize to JSON
                string jsonParams = JsonSerializer.Serialize(license);

                // Encrypt JSON
                byte[] encryptedBlob = CryptoService.Encrypt(jsonParams);

                // Save to file dialog
                using (SaveFileDialog sfd = new SaveFileDialog())
                {
                    sfd.FileName = "license.rar";
                    sfd.Filter = "RAR files (*.rar)|*.rar|All files (*.*)|*.*";
                    sfd.Title = "حفظ ملف الترخيص (يجب إرساله للعميل)";
                    
                    if (sfd.ShowDialog() == DialogResult.OK)
                    {
                        File.WriteAllBytes(sfd.FileName, encryptedBlob);
                        
                        // Save to Local DB
                        _dbService.SaveClient(new ClientRecord
                        {
                            CustomerNo = license.CustomerNo,
                            CustomerName = license.CustomerName,
                            MachineName = license.MachineName,
                            ExpiryDate = license.ExpiryDate,
                            MaxDevices = license.MaxDevices,
                            BranchNo = license.BranchNo,
                            SystemNo = license.SystemNo,
                            StartDate = DateTime.Now
                        });
                        
                        LoadClients();

                        MessageBox.Show("تم توليد ملف الترخيص المشفر (license.rar) بنجاح وحفظ العميل في قاعدة البيانات.", "اكتمل", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("حدث خطأ أثناء التوليد: " + ex.Message, "خطأ", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void dgvClients_CellDoubleClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0)
            {
                var row = dgvClients.Rows[e.RowIndex];
                txtCustomerNo.Text = row.Cells["CustomerNo"].Value?.ToString();
                txtCustomerName.Text = row.Cells["CustomerName"].Value?.ToString();
                txtMachineName.Text = row.Cells["MachineName"].Value?.ToString();
                txtBranch.Text = row.Cells["BranchNo"].Value?.ToString();
                txtSystemVal.Text = row.Cells["SystemNo"].Value?.ToString();
                
                if (DateTime.TryParse(row.Cells["ExpiryDate"].Value?.ToString(), out DateTime expiry))
                {
                    dtpExpiry.Value = expiry;
                }
                
                if (int.TryParse(row.Cells["MaxDevices"].Value?.ToString(), out int maxDev))
                {
                    numMaxDevices.Value = maxDev;
                }
            }
        }
    }
}
"@
Set-Content -Path "$targetDir\Form1.cs" -Value $Form1Code -Encoding UTF8

# 7. Program.cs
$ProgramCode = @"
using System;
using System.Windows.Forms;

namespace HpsLicenseManager
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.SetHighDpiMode(HighDpiMode.SystemAware);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Form1());
        }
    }
}
"@
Set-Content -Path "$targetDir\Program.cs" -Value $ProgramCode -Encoding UTF8

Write-Host "All files created successfully!"
