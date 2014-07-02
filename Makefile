#
#  MakeFile
#  FCGIKit
#
#  Created by Cătălin Stan on 7/1/14.
#  Copyright (c) 2014 Catalin Stan. All rights reserved.


all: clean docs

clean: 
	rm -vrf "../${PRODUCT_NAME}"

docs:
	/usr/local/bin/appledoc \
		--project-name "${PROJECT_NAME}" \
		--project-company "${PROJECT_COMPANY}" \
		--company-id "${COMPANY_ID}" \
		--docset-atom-filename "${PROJECT_NAME}.atom" \
		--docset-feed-url "http://catalinstan.github.com/${PROJECT_NAME}/%DOCSETATOMFILENAME" \
		--docset-package-url "http://catalinstan.github.com/${PROJECT_NAME}/%DOCSETPACKAGEFILENAME" \
		--docset-fallback-url "http://catalinstan.github.com/${PROJECT_NAME}/" \
		--output "../${PRODUCT_NAME}" \
		--publish-docset \
		--logformat xcode \
		--keep-undocumented-objects \
		--keep-undocumented-members \
		--keep-intermediate-files \
		--no-repeat-first-par \
		--no-warn-invalid-crossref \
		--ignore "*.m" \
		--ignore "${PROJECT_DIR}/FCGIKit/Libraries" \
		--index-desc "${PROJECT_DIR}/Readme.md" \
		"${PROJECT_DIR}"