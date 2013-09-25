
#usr/bin/ruby
require 'digest/md5'
require 'base64'

# http://stackoverflow.com/questions/9986971/converting-a-hexadecimal-digest-to-base64-in-ruby
def hex_to_base64_digest(hexdigest)
  [[hexdigest].pack("H*")].pack("m0")
end

# http://stackoverflow.com/questions/3649760/how-to-get-unique-uid
uid = `getent passwd | cut -d: -f3 | sort -n`

# http://stackoverflow.com/questions/17883896/how-do-i-read-a-text-file-into-an-array-of-array-each-sub-array-being-a-row-in
arr = []
uid.lines.each do |line|
    arr << line.chomp!.to_i
end
#puts arr.inspect
#puts arr.sort[-2]
uid = arr.sort[-2]
uid += 1

puts "The next free UID after 1540 is #{uid}"
puts
puts "First name, please."
firstname = gets.chomp
puts "Last name, please."
lastname = gets.chomp
puts
username = firstname.downcase
puts "Username or press enter to use #{username}"
input = gets.chomp
username = input unless input == ""
list = `ls /home`
home_dirs = []
list.lines.each do |line|
   home_dirs << line.chomp!
end

loop do
  puts "Let's check if there is a folder called #{username} already."
  if home_dirs.include? "#{username}"
    puts "\nyou messed the sheets on that one, buddy\n"
    puts "Please enter a *unique* username, for a change."
    input = gets.downcase.chomp
    username = input unless input == ""
  else
    puts "ok, you dodged a bullet on that one."
    break
  end
end

wholename = "#{firstname} #{lastname}"


puts
puts "Type the password please."
userpassword = gets.chomp
puts "You entered: #{userpassword}"

userpasswordhashed = Digest::MD5.hexdigest(userpassword)

userpasswordhashed_b64 = hex_to_base64_digest(userpasswordhashed)
userpasswordhashed_b64 = userpasswordhashed_b64.chomp

puts "userpassword hashed base64: {MD5}#{userpasswordhashed_b64}"

ldif = <<END
dn: cn=#{username},ou=Group,dc=rosemarie,dc=ac,dc=th
cn: #{username}
gidnumber: #{uid}
objectclass: posixGroup


dn: cn=#{wholename},ou=people,dc=rosemarie,dc=ac,dc=th
cn: #{wholename}
displayname: #{wholename}
gecos: #{wholename}
gidnumber: #{uid}
givenname: #{firstname}
homedirectory: /home/#{username}
loginshell: /bin/bash
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: ShadowAccount
sn: #{lastname}
uid: #{username}
uidnumber: #{uid}
userpassword: {MD5}#{userpasswordhashed_b64}
END
puts ldif
File.open("/home/serveradmin/#{username}.ldif", 'w') { |file| file.write("#{ldif}") }


`ldapadd -cxWD cn=admin,dc=rosemarie,dc=ac,dc=th -f #{username}.ldif`
puts
if $?.to_i == 0
  puts "The ldap user was created without errors."
else
  puts "Um, something went wrong. You better use 'control c' to exit this \nprogram and go look at the ldap database and see what went wrong."
end

dir_creator = <<END
sudo mkdir /home/#{username} && sudo cp -R /etc/skel/. /home/#{username} && sudo chown -R #{username}:#{username} /home/#{username} && sudo chmod go-r /home/#{username} && sudo chmod o-x /home/#{username}
END

`#{dir_creator}`

if $?.to_i == 0
  puts "The directories and permissions were successfully created. Probably... Hell I don't know."
else
  puts "Um, something went wrong. You better use 'control c' to exit this \nprogram and go look at the home dir and try to figure out what happend."
end