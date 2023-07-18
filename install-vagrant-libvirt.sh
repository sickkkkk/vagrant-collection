#NOKOGIRI_USE_SYSTEM_LIBRARIES=1
export CONFIGURE_ARGS="with-ldflags=-L/opt/vagrant/embedded/lib with-libvirt-lib=$(brew --prefix libvirt)/lib with-libvirt-include=$(brew --prefix libvirt)/include"
vagrant plugin install vagrant-libvirt
