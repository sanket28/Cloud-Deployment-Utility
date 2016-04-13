from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader
from subprocess import call
import os

"""This renders the index.html page from the templates directory. It fills up the radio buttons from the values in the
	hypervisors and cloudStacks arrays"""
def index(request):
	hypervisors = ["VMWare-vSphere", "Xen-Server", "Microsoft-Hyper-V", "KVM"]
	cloudStacks = ["Apache-CloudStack", "Cloud-Foundry", "RedHat-OpenShift", "None"]
	reboot = ["Yes", "No"]
	template = loader.get_template('manager/index.html')
	context = {
		'hypervisors': hypervisors,
		'cloudStacks': cloudStacks,
		'reboot': reboot
	}

	return HttpResponse(template.render(context, request))


"""This function renders the status.html page from the templates directory. It also takes the request object from the 
	index method and determines the selected cloud configuration and saves it to a file 'cloud_configuration.txt' located
	at /home/cloudmanager. This file is fetched by the shell script running on client machines to determine the cloud
	configuration to deploy"""
def status(request):
	template = loader.get_template('manager/status.html')
	context = {
		'test': 'cool' # We need some kind of context to render the page. This doesn't actually do anything
	}


	if (request.POST):
		save_path = '/home/cloudmanager/'
		if os.path.isfile(save_path+"cloud_configuration.txt") == True: # If the file already exists, remove it
			os.remove(save_path+"cloud_configuration.txt")

		if os.path.isfile(save_path+"reboot.txt") == True: # If the file already exists, remove it
			os.remove(save_path+"reboot.txt")

		cloudConfigPath = os.path.join(save_path, "cloud_configuration.txt")
		rebootConfigPath = os.path.join(save_path, "reboot.txt")

		#print request.POST.get('hypervisorRadios')
		print(cloudConfigPath)
		print(rebootConfigPath)

		file_object = open(cloudConfigPath, 'w') # Open the file for writing
		file_object2 = open(rebootConfigPath, 'w')

		hyperV = request.POST.get('hypervisorRadios') # Get the selected hypervisor
		rebootStatus = request.POST,get('rebootRadios')

		# At the moment we only support KVM, KVM + Apache Cloudstack and XEN, so we only check for those configuraions
		if hyperV == "KVM":
			if request.POST.get('cloudstackRadios') == "Apache-CloudStack":
				print 'KMV-CLOUDSTACK'
				file_object.write("hyp_name=KVM-CLOUDSTACK") # Write to file
				
 			elif request.POST.get('cloudstackRadios') == "None":
 				print "KVM"
 				file_object.write("hyp_name=KVM")

 		elif hyperV == "Xen-Server": 	
			print 'XENSERVER'
 			file_object.write("hyp_name=XENSERVER")
 	
        else:
    		print "Oops! Something is broken."

		file_object.close() # Close the file

		if rebootStatus == "Yes":
			file_object2.write("reboot_status=YES")

		else:
			file_object2.write("reboot_status=NO")

		file_object2.close()

	return HttpResponse(template.render(context, request))