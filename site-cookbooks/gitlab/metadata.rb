name             'gitlab'
maintainer       'Hideki Nakamura'
maintainer_email 'hidecology0302@gmail.com'
license          'All rights reserved'
description      'Installs/Configures gitlab'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w{chef-client build-essential git rbenv}.each do |cb|
	depends cb
end