# risk_profiler_gui.rb
require 'tk'
require 'csv'

class RiskProfiler
  attr_accessor :range_to_type, :type_to_distribution
  
  def initialize
    @range_to_type = {
      [0,10] => :conservative,
      [11,20] => :balanced,
      [21,30] => :moderate,
      [31,40] => :aggressive,
      [41,99] => :v_aggressive
    }
    
    @type_to_distribution = {
      conservative: {equity: 10, debt: 20, commodities: 40, cash: 30},
      balanced: {equity: 10, debt: 20, commodities: 40, cash: 30},
      moderate: {equity: 10, debt: 20, commodities: 40, cash: 30},
      aggressive: {equity: 10, debt: 20, commodities: 40, cash: 30},
      v_aggressive: {equity: 10, debt: 20, commodities: 40, cash: 30},
    }
  end
  
  def score_to_type(score)
    @range_to_type.each do |range, type|
      if range[0] <= score && score <= range[1]
        return type
      end
    end
    nil
  end
  
  def expected_rate_of_return(distribution)
    (2*distribution[:equity] + 3*distribution[:debt] + 
     4*distribution[:commodities] + 7*distribution[:cash]) / (2+3+4+7).to_f
  end
end

class RiskProfilerGUI
  def initialize
    @profiler = RiskProfiler.new
    @input_file = nil
    
    create_gui
  end
  
  def create_gui
    @root = TkRoot.new do
      title "Risk Profiler - Customer Portfolio Generator"
      geometry "600x300"
      resizable false, false
    end
    
    # Title
    TkLabel.new(@root) do
      text "Risk Profile Generator"
      font TkFont.new('Arial 16 bold')
      pack(pady: 20)
    end
    
    # File selection frame
    file_frame = TkFrame.new(@root).pack(pady: 10, padx: 20, fill: 'x')
    
    TkLabel.new(file_frame) do
      text "Input CSV File:"
      pack(side: 'left', padx: 5)
    end
    
    @file_label = TkLabel.new(file_frame) do
      text "No file selected"
      relief 'sunken'
      width 40
      pack(side: 'left', padx: 5)
    end
    
    TkButton.new(file_frame) do
      text "Browse..."
      command { browse_file }
      pack(side: 'left', padx: 5)
    end
    
    # Status label
    @status_label = TkLabel.new(@root) do
      text ""
      font TkFont.new('Arial 10')
      foreground 'blue'
      pack(pady: 20)
    end
    
    # Generate button
    @generate_btn = TkButton.new(@root) do
      text "Generate Risk Profiles"
      font TkFont.new('Arial 12 bold')
      state 'disabled'
      command { generate_profiles }
      pack(pady: 10)
    end
    
    # Instructions
    TkLabel.new(@root) do
      text "Instructions:\n1. Click 'Browse' to select your input CSV file\n2. Click 'Generate Risk Profiles' to process\n3. Output will be saved as 'customer_riskprofile_outcomes.csv'"
      font TkFont.new('Arial 9')
      justify 'left'
      foreground 'gray'
      pack(pady: 15)
    end
  end
  
  def browse_file
    filename = Tk.getOpenFile(
      'filetypes' => [['CSV Files', '.csv'], ['All Files', '*']],
      'title' => 'Select Input CSV File'
    )
    
    if filename && !filename.empty?
      @input_file = filename
      @file_label.text = File.basename(filename)
      @generate_btn.state = 'normal'
      @status_label.text = "File loaded: #{File.basename(filename)}"
      @status_label.foreground = 'green'
    end
  end
  
  def generate_profiles
    unless @input_file && File.exist?(@input_file)
      show_error("Please select a valid CSV file first!")
      return
    end
    
    begin
      @status_label.text = "Processing..."
      @status_label.foreground = 'blue'
      @generate_btn.state = 'disabled'
      @root.update
      
      processed_count = 0
      
      CSV.open("customer_riskprofile_outcomes.csv", "wb") do |csv|
        csv << ['Name', 'Email', 'Contact No', 'Portfolio']
        
        CSV.foreach(@input_file, headers: true) do |row|
          score = row['Total score'][0..2].to_i
          type = @profiler.score_to_type(score)
          csv << [row['Name'], row['Username'], row['Contact No'], type.to_s]
          processed_count += 1
        end
      end
      
      show_success("Success! Processed #{processed_count} customers.\n\nOutput saved to:\ncustomer_riskprofile_outcomes.csv")
      @generate_btn.state = 'normal'
      
    rescue => e
      show_error("Error processing file:\n#{e.message}")
      @generate_btn.state = 'normal'
    end
  end
  
  def show_error(message)
    Tk.messageBox(
      'type' => 'ok',
      'icon' => 'error',
      'title' => 'Error',
      'message' => message
    )
    @status_label.text = "Error occurred"
    @status_label.foreground = 'red'
  end
  
  def show_success(message)
    Tk.messageBox(
      'type' => 'ok',
      'icon' => 'info',
      'title' => 'Success',
      'message' => message
    )
    @status_label.text = "Processing complete!"
    @status_label.foreground = 'green'
  end
  
  def run
    Tk.mainloop
  end
end

# Run the application
RiskProfilerGUI.new.run