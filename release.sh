#!/bin/bash

NAME="MKV-to-MP4"
VER=1.1

rm ${NAME}-v${VER}.tar* 2>/dev/null
bzr export ${NAME}-v${VER}.tar
tar --delete -f ${NAME}-v${VER}.tar ${NAME}-v${VER}/release.sh
gzip ${NAME}-v${VER}.tar

IFS=$'\n'
DATE=`date`
SIZE_B=`stat -c%s ${NAME}-v${VER}.tar.gz`
SIZE_KB=`echo "scale=2; ${SIZE_B} / 1024" | bc`

HTML_HEADER=`cat << EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
  <title>Flexion.Org</title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <link rel="stylesheet" href="http://www.flexion.org/style.css" type="text/css" media="screen" />
  <link rel="stylesheet" href="http://www.flexion.org/style_custom.css" type="text/css" media="screen" />
  <!--[if IE]><link rel="stylesheet" href="http://www.flexion.org/ie.css" type="text/css" media="screen" /><![endif]-->
  <link rel="stylesheet" type="text/css" href="http://www.flexion.org/style_print.css" media="print" />
  <link rel="icon" type="image/x-icon" href="http://www.flexion.org/favicon.ico"  />
  <link rel="shortcut icon" type="image/x-icon" href="http://www.flexion.org/favicon.ico" />
  <link rel="apple-touch-icon" href="http://www.flexion.org/gravatar_iphone.jpg"/>  
  <meta name="verify-v1" content="sTD+Tg70Ya7mIYwjt+CO01makbQt/fmX1x7e7iH00M8=" />
  <meta name="msvalidate.01" content="2ABB3EC9FB040F7E5092CF46BCE076D0" />
  <meta name="y_key" content="c1a7fc1b398dd026" />
</head>

<body>
    <div id="wrapper">
        <div id="header">
            <!-- Blog Description -->
            <div id="blackband_top_left">
                <h2>Bad grammar and typos for total strangers</h2>
            </div>

            <!-- Page Navigation -->
            <div id="blackband_top_right">
                <ul>
                    <li class="page_item"><a href="http://www.flexion.org" title="Home">Home</a></li>
                    <li class="page_item"><a href="http://blog.flexion.org" title="Blog">Blog</a></li>
                    <li class="page_item"><a href="http://wiki.flexion.org" title="Wiki">Wiki</a></li>
		    		<li class="page_item"><a href="http://code.flexion.org" title="Code">Code</a></li>
                </ul>
            </div>

            <!-- Blog Title -->
            <div id="header_siteheader">
                <a href="http://twitter.com/statuses/user_timeline/18991793.rss" title="Subscribe to my Twitter Feed (RSS)" rel="nofollow"><img src="http://blog.flexion.org/wp-content/themes/grey_matter_2/img/rss_logo.png" alt="Subscribe to my Twitter Feed (RSS)" /></a>
                <h1><a href="http://www.flexion.org">Flexion.Org</a></h1>
            </div>

            <!-- Header Sidebar -->
            <div id="header_sidebar">
	            <form action="http://code.flexion.org/results.html" id="searchform">
  	            <!-- <div> -->
	                <input type="hidden" name="cx" value="001632951320533292515:prnkn0j7q3m" />
	                <input type="hidden" name="cof" value="FORID:11" />
	                <input type="hidden" name="ie" value="UTF-8" />
	                <input type="text" value="Search" name="q" id="s" size="20" onfocus="if (this.value == 'Search') {this.value = '';}" onblur="if (this.value == '') {this.value = 'Search';}" />
	                <input type="submit" name="sa" id="searchsubmit" value="Find" />
	            <!-- </div> -->
	            </form>
	            <script type="text/javascript" src="http://www.google.com/coop/cse/brand?form=cse-search-box&amp;lang=en"></script>
            </div>
        </div>

        <div id="content">
	        <h1><a href="http://code.flexion.org/${NAME}.html" rel="bookmark" title="${NAME}">${NAME} v${VER}</a></h1>
EOF`

HTML_FOOTER=`cat << EOF
			</pre>
    	    	<div id="postmeta">
		        Last Updated&nbsp;&bull;&nbsp;${DATE}
	        </div>
        </div>

        <div id="sidebar">
            <ul>
                <li id="ubuntu" class="widget">
	            <h2 class="widgettitle">Ubuntu</h2>
                    <div align="center">
	                <script type="text/javascript" src="http://crunchbang.net/advocacy/ubuntu_199_164.js"></script>
                        <noscript>
		        	<a href="http://ubuntu.com/getubuntu" title="Get Ubuntu!" target="_blank"><img src="http://crunchbang.net/advocacy/199_164_ubuntu.png" alt="Get Ubuntu!" /></a>
	                </noscript>
	            </div>
                </li>
            </ul>
        </div>

        <div id="footer">
  	        <div id="blackband_bottom_left">&copy; <a href="http://www.flexion.org">Flexion.Org</a>.</div>
	        <div id="blackband_bottom_right">Theme: <a href="http://masnikov.com/grey_matter">Grey Matter</a>.</div>
        </div>
    </div>
    <script type="text/javascript">
        try {
            var pageTracker = _gat._getTracker("UA-7055643-2");
            pageTracker._trackPageview();
        } catch(err) {}
    </script>
</body>
</html>
EOF`

echo ${HTML_HEADER} >  ${NAME}.html

cat << EOF >> ${NAME}.html
<h2>Documentation</h2>
EOF

echo "<pre>"        >> ${NAME}.html
cat README.txt      >> ${NAME}.html
echo "</pre>"       >> ${NAME}.html

cat << EOF >> ${NAME}.html
<h2>Download</h2>
<ul>
<li><a href="http://code.flexion.org/${NAME}-v${VER}.tar.gz">${NAME}-v${VER}.tar.gz</a> (${SIZE_KB} Kb)</li>
</ul>
EOF

echo ${HTML_FOOTER} >> ${NAME}.html

if [ -e /etc/release.conf ]; then

#   Here is an example 'release.conf'	
#
#	SSH_PRIMARY="ssh_user@primary.example.org:/path/to/publish"
#	SSH_MIRROR="ssh_user@mirror.example.org:/path/to/publish"
#
#   T_USERNAME="twitter_user"
#	T_PASSWORD="twitter_pass"
#
#	I_USERNAME="identica_user"
#	I_PASSWORD="identica_pass"

	source /etc/release.conf
	if [ -n ${SSH_PRIMARY} ]; then
		echo "Publishing to SSH Primary"
		scp ${NAME}-v${VER}.tar.gz ${NAME}.html ${SSH_PRIMARY}
	
		if [ -n ${T_USERNAME} ] && [ -n ${T_PASSWORD} ]; then	
			echo "Notifying Twitter"
	  		#curl -u ${T_USERNAME}:${T_PASSWORD} -d status="Code Released, \"${NAME} v${VER}\" - http://code.flexion.org/${NAME}.html" https://twitter.com/statuses/update.xml -k >& /dev/null
		else
			"WARNING! Twitter account details are missing."
		fi	  		
		
		if [ -n ${I_USERNAME} ] && [ -n ${I_PASSWORD} ]; then	
			echo "Notifying Identica"
		  	#curl -u ${I_USERNAME}:${I_PASSWORD} -d status="Code Released, \"${NAME} v${VER}\" - http://code.flexion.org/${NAME}.html" https://identi.ca/api/statuses/update.xml -k >& /dev/null			
		else
			"WARNING! Identica account details are missing."		
		fi
	else
		echo "ERROR! SSH Primary publication details are missing."	  	
	fi		  	
	if [ -n ${SSH_MIRROR} ]; then
		echo "Publishing to SSH Mirror"	
		scp ${NAME}-v${VER}.tar.gz ${NAME}.html ${SSH_MIRROR}
	else
		echo "ERROR! SSH Mirror publication details are missing."	  		
	fi			
else
	echo "WARNING! The release is built but not published"
fi

rm ${NAME}-v${VER}.tar.gz ${NAME}.html 2>/dev/null
