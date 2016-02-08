from django.shortcuts import render
from django.http import HttpResponse
from django.template import loader

def index(request):
	hypervisors = ["VMWare", "XEN", "Microsoft"]
	template = loader.get_template('manager/index.html')
	context = {
		'hypervisors': hypervisors
	}
	return HttpResponse(template.render(context, request))
