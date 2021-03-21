FLAGS=

ORDERED_PAGES=preface intro history http graphics text html layout styles chrome forms scripts reflow security visual-effects skipped change glossary

PANDOC_COMMON_ARGS=--from markdown --to html --lua-filter=book/filter.lua --fail-if-warnings

HTML_EXAMPLES=www/layout-example.html www/layout-container-example.html

book: $(patsubst book/%.md,www/%.html,$(wildcard book/*.md)) www/draft/onepage.html $(patsubst book/%-example.html,www/draft/%-example.html,$(wildcard book/*-example.html))
blog: $(patsubst blog/%.md,www/blog/%.html,$(wildcard blog/*.md))
draft: $(patsubst book/%.md,www/draft/%.html,$(wildcard book/*.md)) $(patsubst book/%-example.html,www/draft/%-example.html,$(wildcard book/*-example.html))

onepage/%.html: book/%.md book/template-onepage.html book/filter.lua disabled.conf
	mkdir -p $(dir $@)
	pandoc --toc --template book/template-onepage.html $(FLAGS) -c book.css --variable=script:feedback.js $(PANDOC_COMMON_ARGS) --metadata=mode:draft -c ../book.css $< -o $@

onepage/%-quicklink.html: book/%.md book/quicklink.html book/filter.lua disabled.conf
	mkdir -p $(dir $@)
	pandoc --toc --template book/quicklink.html $(FLAGS) --variable=script:feedback.js $(PANDOC_COMMON_ARGS) $< -o $@

www/draft/onepage.html: $(patsubst book/%.md,onepage/%.html,$(wildcard book/*.md)) $(patsubst book/%.md,onepage/%-quicklink.html,$(wildcard book/*.md)) book/onepage-head.html
	mkdir -p $(dir $@)
	cat book/onepage-head.html  $(patsubst %,onepage/%-quicklink.html,$(ORDERED_PAGES)) $(patsubst %,onepage/%.html,$(ORDERED_PAGES)) > www/draft/onepage.html

www/%.html: book/%.md book/template.html book/signup.html book/filter.lua disabled.conf
	mkdir -p $(dir $@)
	pandoc --toc --template book/template.html $(FLAGS) -c book.css --variable=script:feedback.js $(PANDOC_COMMON_ARGS) $< -o $@

www/blog/%.html: blog/%.md book/template.html book/filter.lua disabled.conf
	mkdir -p $(dir $@)
	pandoc --metadata=toc:none --template book/template.html $(FLAGS) -c ../book.css $(PANDOC_COMMON_ARGS) $< -o $@

www/draft/%.html: book/%.md book/template.html book/signup.html book/filter.lua
	@ mkdir -p $(dir $@)
	pandoc --toc --template book/template.html $(FLAGS) \
	       --metadata=mode:draft --variable=script:../feedback.js \
               -c ../book.css $(PANDOC_COMMON_ARGS) \
               $< -o $@

www/%-example.html: book/%-example.html
	cp $< www/

www/draft/%-example.html: book/%-example.html
	cp $< www/draft/

publish:
	rsync -rtu --exclude=*.pickle --exclude=*.hash www/ server:/home/www/browseng/
	ssh server chmod -Rf a+r /home/www/browseng/ || true
	ssh server sudo systemctl restart browser-engineering.service

download:
	rsync -r 'server:/home/www/browseng/*.pickle' www/

clean:
	rm $(html)
