Backup::Model.new(:munin, 'Munin Server') do
  archive :lib do |archive|
    archive.add '/var/lib/munin'
  end
  eval(IO.read('/etc/backup/global.rb'))
end
