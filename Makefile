sanity:
	./generate-fbc.sh --comment-graph-all
	./generate-fbc.sh --render-all
	git diff --exit-code

sanity-brew:
	./generate-fbc.sh --comment-graph-all brew
	./generate-fbc.sh --render-all brew
	git diff --exit-code

check-prod:
	./generate-fbc.sh --init-basic-all
	git diff HEAD --no-ext-diff --patience --unified=0 -a --no-prefix "v4.*/graph.yaml" | grep -e "^+" | grep -v -e "^+++" | grep -v v4.99.0 || true
	NUMLL=$$(git diff HEAD --no-ext-diff --patience --unified=0 -a --no-prefix "v4.*/graph.yaml" | grep -e "^+" | grep -v -e "^+++" | grep -v v4.99.0 || true | wc -l) && echo "Lost Lines: $$NUMLL" && exit $$NUMLL

.PHONY: sanity sanity-brew check-prod
