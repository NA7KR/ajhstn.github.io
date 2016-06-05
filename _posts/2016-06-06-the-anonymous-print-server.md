---
layout: post
title: The Anonymous Print Server
comments: false
---
Today i will configuring an anonymous print server, meaning anyone, anytime, no quetions asked can print to it.

While this is not a normal production setup, it meets our requirements for an event we are hosting.  For this event we are in a venue hire with limited network cnnectivity, and 100's of hired computers not bound to our domain (and no, we dont want to bind them).  The requirement is these machines need to be able to use Remote Desktop Services, Print Services and Internet Services.

First i will ~stand up~ (gee i hate that "buzz" word, stop using it please!) a virtual machine, in my case, a Hyper-V Windows Server 2012R2 VM guest.