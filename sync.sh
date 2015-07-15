#!/bin/bash

SDIR="/home/jenkins/jenkins_home/jobs/ose_implementation/lastSuccessful/archive"
DDIR="/var/www/html/classes/ose3-class"

scp -q $SDIR/LabInstructionsFiles/*.html www.opentlc.com:$DDIR/html
scp -q $SDIR/LabInstructionsFiles/*.pdf www.opentlc.com:$DDIR/pdf
scp -q $SDIR/scormFiles/*.zip www.opentlc.com:$DDIR/html
ssh www.opentlc.com 'cd '$DDIR'/html;for zip in *.zip; do dn=`echo $zip|sed 's/.zip//'`;rm -rf '$DDIR'/html/$dn;mkdir -p '$DDIR'/html/$dn;cd '$DDIR'/html/$dn;unzip -oq '$DDIR'/html/$zip;rm -f '$DDIR'/html/$zip;sed -i "s/<audio.*audio>//" '$DDIR'/html/$dn/AllSlides.html; done'

ssh www.opentlc.com "chmod -R g+w $DDIR;chgrp -R rhpds-sysadmins $DDIR;restorecon -R $DDIR"
