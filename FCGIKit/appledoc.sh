#!/bin/sh

#  appledoc.sh
#  FCGIKit
#
#  Created by Cătălin Stan on 7/1/14.
#  Copyright (c) 2014 Catalin Stan. All rights reserved.

ORGANIZATION_NAME="Catalin Stan"
COMPANY_ID="com.catalinstan"

/usr/local/bin/appledoc \
--project-name "${PROJECT_NAME}" \
--project-company "${ORGANIZATION_NAME}" \
--company-id "${COMPANY_ID}" \
--docset-atom-filename "FCGIKit.atom" \
--docset-feed-url "http://catalinstan.github.com/FCGIKit/%DOCSETATOMFILENAME" \
--docset-package-url "http://catalinstan.github.com/FCGIKit/%DOCSETPACKAGEFILENAME" \
--docset-fallback-url "http://catalinstan.github.com/FCGIKit/" \
--output "${PROJECT_DIR}/../FCGIKit Documentation" \
--publish-docset \
--logformat xcode \
--keep-undocumented-objects \
--keep-undocumented-members \
--keep-intermediate-files \
--no-repeat-first-par \
--no-warn-invalid-crossref \
--ignore "*.m" \
--index-desc "${PROJECT_DIR}/readme.markdown" \
"${PROJECT_DIR}"