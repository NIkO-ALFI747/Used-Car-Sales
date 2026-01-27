using Npgsql;
using System.Data;

namespace Used_Car_Sales
{
    public partial class MainForm : Form
    {
        private string connString = "Host=localhost;Port=5432;Username=postgres;Password=postgres;Database=db_cars_sale";

        private int currenRowID = 0;

        public MainForm()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            RefreshAllGrids();
        }

        private void RefreshAllGrids()
        {
            FillGrid("SELECT * FROM \"FULL_CAR\"", dataGridView6);
            FillGrid("SELECT * FROM \"OWNERS_INDIVIDUAL_INFO\"", dataGridView5);
            FillGrid("SELECT * FROM \"CUSTOMERS_INDIVIDUAL_INFO\"", dataGridView4);
            FillGrid("SELECT * FROM \"MANAGERS_INDIVIDUAL_INFO\"", dataGridView3);
            FillGrid("SELECT * FROM \"CONTRACT_INFO\"", dataGridView2);
            FillGrid("SELECT * FROM \"CAR_MODERN\"", dataGridView1);
        }

        private void FillGrid(string sql, DataGridView grid)
        {
            try
            {
                using (var conn = new NpgsqlConnection(connString))
                {
                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(sql, conn);
                    DataTable dt = new DataTable();
                    da.Fill(dt);
                    grid.DataSource = dt;
                }
            }
            catch (Exception ex) { MessageBox.Show("Error loading data: " + ex.Message); }
        }

        private void button1_Click(object sender, EventArgs e)
        {
            try
            {
                using (var conn = new NpgsqlConnection(connString))
                {
                    conn.Open();
                    using (var cmd = new NpgsqlCommand("SELECT \"Insert_Car\"(@vin, @avail, @brand, @model, @mileage, @year, @price, @status)", conn))
                    {
                        cmd.Parameters.AddWithValue("vin", textBox1.Text);
                        cmd.Parameters.AddWithValue("avail", comboBox1.SelectedItem?.ToString() == "Да");
                        cmd.Parameters.AddWithValue("brand", textBox4.Text);
                        cmd.Parameters.AddWithValue("model", textBox5.Text);
                        cmd.Parameters.AddWithValue("mileage", int.Parse(textBox3.Text));
                        cmd.Parameters.AddWithValue("year", int.Parse(comboBox2.SelectedItem.ToString()));
                        cmd.Parameters.AddWithValue("price", int.Parse(textBox2.Text));
                        cmd.Parameters.AddWithValue("status", 3);
                        cmd.ExecuteNonQuery();
                    }
                }
                RefreshAllGrids();
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            if (dataGridView1.SelectedRows.Count == 0) return;
            try
            {
                using (var conn = new NpgsqlConnection(connString))
                {
                    conn.Open();
                    string id = dataGridView1.SelectedRows[0].Cells["ID_car"].Value.ToString();
                    using (var cmd = new NpgsqlCommand("DELETE FROM \"Car\" WHERE \"ID_car\" = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("id", int.Parse(id));
                        cmd.ExecuteNonQuery();
                    }
                }
                RefreshAllGrids();
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
        }

        private void button4_Click(object sender, EventArgs e)
        {
            try
            {
                using (var conn = new NpgsqlConnection(connString))
                {
                    conn.Open();
                    int newProdID = 0;
                    string sql =
                        @"SELECT ""Insert_individual""(
                        @p1::""name-or-passport"", 
                        @p2::""name-or-passport"", 
                        @p3::varchar, 
                        @p4::""phone-or-address"", 
                        @p5::""phone-or-address"", 
                        @p6::""phone-or-address"", 
                        @p7::""phone-or-address"", 
                        @p8::""name-or-passport"", 
                        @p9::""name-or-passport"", 
                        @p10::date, 
                        @p11::""phone-or-address"")";
                    using (var cmd = new NpgsqlCommand(sql, conn))
                    {
                        cmd.Parameters.Add("p1", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox8.Text;
                        cmd.Parameters.Add("p2", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox9.Text;
                        cmd.Parameters.Add("p3", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox7.Text;
                        cmd.Parameters.Add("p4", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox6.Text;
                        cmd.Parameters.Add("p5", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox10.Text;
                        cmd.Parameters.Add("p6", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox11.Text;
                        cmd.Parameters.Add("p7", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox12.Text;
                        cmd.Parameters.Add("p8", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox13.Text;
                        cmd.Parameters.Add("p9", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox14.Text;
                        if (DateTime.TryParse(textBox16.Text, out DateTime issuedDate))
                        {
                            cmd.Parameters.Add("p10", NpgsqlTypes.NpgsqlDbType.Date).Value = issuedDate;
                        }
                        else
                        {
                            MessageBox.Show("Invalid date format in textBox16!");
                            return;
                        }
                        cmd.Parameters.Add("p11", NpgsqlTypes.NpgsqlDbType.Varchar, 30).Value = textBox15.Text;
                        newProdID = Convert.ToInt32(cmd.ExecuteScalar());
                    }
                    string tableType = comboBox4.SelectedItem.ToString();
                    string targetTable = tableType == "Менеджер" ? "Manager" : (tableType == "Клиент" ? "Buyer" : "Owner");
                    using (var cmd2 = new NpgsqlCommand($"INSERT INTO \"{targetTable}\" (\"ID_individual\") VALUES (@id)", conn))
                    {
                        cmd2.Parameters.AddWithValue("id", newProdID);
                        cmd2.ExecuteNonQuery();
                    }
                }
                RefreshAllGrids();
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
        }

        private void button5_Click(object sender, EventArgs e)
        {
            string sortDir = comboBox5.SelectedItem.ToString() == "По возрастанию" ? "ASC" : "DESC";
            string column = "Customers_sername";
            if (comboBox3.SelectedIndex == 1) column = "Customers_name";
            if (comboBox3.SelectedIndex == 2) column = "Customers_city";
            if (comboBox3.SelectedIndex == 3) column = "Managers_sername";
            string sql = $"SELECT * FROM \"CONTRACT_INFO\" ORDER BY \"{column}\" {sortDir}";
            FillGrid(sql, dataGridView2);
        }

        private void button7_Click(object sender, EventArgs e)
        {
            string col = GetColumnName(comboBox6.SelectedItem.ToString());
            try
            {
                using (var conn = new NpgsqlConnection(connString))
                {
                    string sql = $"SELECT * FROM \"CONTRACT_INFO\" WHERE \"{col}\"::text LIKE @search";
                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(sql, conn);
                    da.SelectCommand.Parameters.AddWithValue("search", textBox19.Text + "%");
                    DataTable dt = new DataTable();
                    da.Fill(dt);
                    dataGridView2.DataSource = dt;
                }
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
        }

        private string GetColumnName(string russianName)
        {
            return russianName switch
            {
                "Фамилия клиента" => "Customers_sername",
                "Имя клиента" => "Customers_name",
                "Марка автомобиля" => "Brand",
                "Цена автомобиля" => "Price",
                _ => "Customers_sername"
            };
        }

        private void button8_Click(object sender, EventArgs e)
        {
            try
            {
                using (var conn = new NpgsqlConnection(connString))
                {
                    string sql = "SELECT * FROM \"FULL_CAR\" WHERE \"Price\" > @min AND \"Price\" < @max";
                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(sql, conn);
                    da.SelectCommand.Parameters.AddWithValue("min", int.Parse(textBox21.Text));
                    da.SelectCommand.Parameters.AddWithValue("max", int.Parse(textBox20.Text));
                    DataTable dt = new DataTable();
                    da.Fill(dt);
                    dataGridView6.DataSource = dt;
                }
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
        }

        private void button3_Click(object sender, EventArgs e)
        {
            if (currenRowID == 0) return;
            try
            {
                using (var conn = new NpgsqlConnection(connString))
                {
                    conn.Open();
                    using (var cmd = new NpgsqlCommand("SELECT \"Update_Car\"(@vin, @avail, @brand, @model, @mileage, @year, @price, @status, @id)", conn))
                    {
                        cmd.Parameters.AddWithValue("vin", textBox1.Text);
                        cmd.Parameters.AddWithValue("avail", comboBox1.SelectedItem?.ToString() == "Да");
                        cmd.Parameters.AddWithValue("brand", textBox4.Text);
                        cmd.Parameters.AddWithValue("model", textBox5.Text);
                        cmd.Parameters.AddWithValue("mileage", int.Parse(textBox3.Text));
                        cmd.Parameters.AddWithValue("year", int.Parse(comboBox2.SelectedItem.ToString()));
                        cmd.Parameters.AddWithValue("price", int.Parse(textBox2.Text));
                        cmd.Parameters.AddWithValue("status", 3);
                        cmd.Parameters.AddWithValue("id", currenRowID);
                        cmd.ExecuteNonQuery();
                    }
                }
                RefreshAllGrids();
                MessageBox.Show("Данные успешно обновлены");
            }
            catch (Exception ex) { MessageBox.Show("Ошибка обновления: " + ex.Message); }
        }

        private void button6_Click(object sender, EventArgs e)
        {
            try
            {
                string sql = "SELECT * FROM \"CONTRACT_INFO\" WHERE \"Price\" > @min AND \"Price\" < @max";
                using (var conn = new NpgsqlConnection(connString))
                {
                    NpgsqlDataAdapter da = new NpgsqlDataAdapter(sql, conn);
                    da.SelectCommand.Parameters.AddWithValue("min", decimal.Parse(textBox17.Text));
                    da.SelectCommand.Parameters.AddWithValue("max", decimal.Parse(textBox18.Text));
                    DataTable dt = new DataTable();
                    da.Fill(dt);
                    dataGridView2.DataSource = dt;
                }
            }
            catch (Exception ex) { MessageBox.Show("Ошибка фильтрации: " + ex.Message); }
        }

        private void dataGridView1_RowEnter(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex < 0) return;
            try
            {
                var row = dataGridView1.Rows[e.RowIndex];
                textBox1.Text = row.Cells["vin"].Value?.ToString();
                textBox4.Text = row.Cells["brand"].Value?.ToString();
                textBox5.Text = row.Cells["model"].Value?.ToString();
                textBox2.Text = row.Cells["price"].Value?.ToString();
                textBox3.Text = row.Cells["mileage"].Value?.ToString();
                string avail = row.Cells["availability"].Value?.ToString();
                comboBox1.SelectedItem = (avail == "True" || avail == "1") ? "Да" : "Нет";
                comboBox2.SelectedItem = row.Cells["year_of_issue"].Value?.ToString();
                currenRowID = Convert.ToInt32(row.Cells["ID_car"].Value);
            }
            catch {}
        }

        private void label9_Click(object sender, EventArgs e)
        {
        }

        private void tabPage3_Click(object sender, EventArgs e)
        {
        }
    }
}
