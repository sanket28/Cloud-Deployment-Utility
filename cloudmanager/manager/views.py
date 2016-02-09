from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader

def index(request):
	hypervisors = ["VMWare vSphere", "Xen Server", "Microsoft Hyper-V"]
	cloudStacks = ["Apache CloudStack", "Cloud Foundry", "RedHat OpenShift"]
	template = loader.get_template('manager/index.html')
	context = {
		'hypervisors': hypervisors,
		'cloudStacks': cloudStacks
	}
	return HttpResponse(template.render(context, request))
