build:
	bundle install
	bundle exec jekyll build

serve:
	bundle exec jekyll serve --incremental

push:
	git add .
	git commit -m "update"
	git push