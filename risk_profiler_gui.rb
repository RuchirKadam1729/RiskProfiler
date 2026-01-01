cat > risk_profiler_gui.rb << 'EOF'
require 'webrick'
require 'csv'

class RiskProfiler
  def initialize
    @range_to_type = {
      [0,10] => :conservative,
      [11,20] => :balanced,
      [21,30] => :moderate,
      [31,40] => :aggressive,
      [41,99] => :v_aggressive
    }
  end
  
  def score_to_type(score)
    @range_to_type.each { |range, type| return type if range[0] <= score && score <= range[1] }
    nil
  end
end

HTML = <<-HTML
<!DOCTYPE html>
<html>
<head>
<title>Risk Profiler</title>
<style>
body{font-family:Arial;max-width:600px;margin:50px auto;padding:20px}
h1{color:#333}
.btn{background:#007bff;color:white;padding:10px 20px;border:none;border-radius:5px;cursor:pointer;font-size:16px;margin:10px 0}
.btn:hover{background:#0056b3}
#status{margin:20px 0;padding:10px;border-radius:5px}
.success{background:#d4edda;color:#155724}
.error{background:#f8d7da;color:#721c24}
</style>
</head>
<body>
<h1>Risk Profile Generator</h1>
<input type="file" id="file" accept=".csv">
<br><button class="btn" onclick="process()">Generate Profiles</button>
<div id="status"></div>
<script>
function process(){
  const file = document.getElementById('file').files[0];
  if(!file){alert('Select a CSV file first!');return;}
  const formData = new FormData();
  formData.append('file', file);
  fetch('/process', {method:'POST', body:formData})
    .then(r=>r.json())
    .then(d=>{
      document.getElementById('status').className=d.success?'success':'error';
      document.getElementById('status').textContent=d.message;
    });
}
</script>
</body>
</html>
HTML

server = WEBrick::HTTPServer.new(Port: 8080, AccessLog: [], Logger: WEBrick::Log.new("/dev/null"))

server.mount_proc '/process' do |req, res|
  profiler = RiskProfiler.new
  begin
    csv_data = req.query['file']
    input = CSV.parse(csv_data, headers: true)
    
    CSV.open("customer_riskprofile_outcomes.csv", "wb") do |csv|
      csv << ['Name', 'Email', 'Contact No', 'Portfolio']
      input.each do |row|
        score = row['Total score'][0..2].to_i
        type = profiler.score_to_type(score)
        csv << [row['Name'], row['Username'], row['Contact No'], type.to_s]
      end
    end
    
    res.body = {success: true, message: "Success! Processed #{input.size} customers. Check customer_riskprofile_outcomes.csv"}.to_json
  rescue => e
    res.body = {success: false, message: "Error: #{e.message}"}.to_json
  end
  res.content_type = 'application/json'
end

server.mount_proc '/' do |req, res|
  res.body = HTML
  res.content_type = 'text/html'
end

puts "Opening browser at http://localhost:8080"
system("start http://localhost:8080") rescue system("open http://localhost:8080")
server.start
EOF

