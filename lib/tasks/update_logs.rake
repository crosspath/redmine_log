desc "Update table 'logs': set controller"
task :update_logs => :environment do
  c = Issue.connection
  counter = 0
  batch_size = 1000
  res = []
  
  log_on_error = -> r, &block do begin
    block.call r
  rescue => e
    p e
    res << r
  end end
  ctrl = -> v { v == 'null' ? v : JSON.parse(v)['controller'] }
  
  begin
    rows = c.select_rows "SELECT id, parameters FROM logs LIMIT #{counter*batch_size}, #{batch_size}"
    rows.each do |r|
      log_on_error.call(r) { c.update "UPDATE logs SET controller = '#{ctrl.call(r[1])}' WHERE id = #{r[0]}" }
    end
    puts counter*batch_size
    counter += 1
  end while rows.size == batch_size
  puts('Skipped records:', res) if res.many?
end
