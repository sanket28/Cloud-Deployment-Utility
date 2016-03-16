from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader
from subprocess import call
import os


def index(request):
	hypervisors = ["VMWare-vSphere", "Xen-Server", "Microsoft-Hyper-V", "KVM"]
	cloudStacks = ["Apache-CloudStack", "Cloud-Foundry", "RedHat-OpenShift", "None"]
	template = loader.get_template('manager/index.html')
	context = {
		'hypervisors': hypervisors,
		'cloudStacks': cloudStacks
	}

	return HttpResponse(template.render(context, request))

def status(request):
	template = loader.get_template('manager/status.html')
	context = {
		'test': 'cool'
	}


	if (request.POST):
		save_path = '/usr/share/nginx/html/'
		if os.path.isfile(save_path+"Shell_file.txt") == True:
			os.remove(save_path+"Shell_file.txt")

		completeName = os.path.join(save_path, "Shell_file.txt")
		print request.POST.get('hypervisorRadios')
		print(completeName)
		file_object = open(completeName, 'w')
		hyperV = request.POST.get('hypervisorRadios')

		if hyperV == "KVM":
			if request.POST.get('cloudstackRadios') == "Apache-CloudStack":
				print 'KMV-CLOUDSTACK'
				
				file_object.write("hyp_name=KVM-CLOUDSTACK")
				
 			else:
 				print "KVM"
 				file_object.write("hyp_name=KVM")

 		elif hyperV == "Xen-Server": 	
			print 'XENSERVER'
 			file_object.write("hyp_name=XENSERVER")
 		#print call(["ls", "-l"])
        else:
    		print "Oops! Something is broken."
		file_object.close()
	return HttpResponse(template.render(context, request))