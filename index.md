---
layout: default
title: ajhstn's code
comments: false
---

## Hello
Here i share PowerShell script that i have put together over time during my days in system/infrastructure engineering.

I fit into the group of "beginner++" coders, my point being, i encourage your feedback and comments..

### Posts
{% for post in site.posts %}
{{ post.date | date: "%Y/%m" }} >> [{{ post.title }}]({{ post.url }})
{{ post.excerpt }}
{% endfor %}
