Backup::Model.new(:munin, 'Munin Server') do
  archive :lib do |archive|
    archive.add '/var/lib/munin'
    archive.exclude '/var/lib/munin/cgi-tmp'
  end
  eval(IO.read('/etc/backup/global.rb'))
end
