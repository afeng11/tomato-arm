<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.0//EN'>
<!--
	Tomato GUI
	Copyright (C) 2006-2010 Jonathan Zarate
	http://www.polarcloud.com/tomato/

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv='content-type' content='text/html;charset=utf-8'>
<meta name='robots' content='noindex,nofollow'>
<title>[<% ident(); %>] <% translate("Bandwidth"); %>: <% translate("Weekly"); %></title>
<link rel='stylesheet' type='text/css' href='tomato.css'>
<link rel='stylesheet' type='text/css' href='color.css'>
<script type='text/javascript' src='tomato.js'></script>

<!-- / / / -->

<script type='text/javascript' src='debug.js'></script>
<script type='text/javascript' src='bwm-hist.js'></script>

<script type='text/javascript'>

//	<% nvram("wan_ifname,wan2_ifname,wan3_ifname,wan4_ifname,lan_ifname,rstats_enable"); %>
try {
//	<% bandwidth("daily"); %>
}
catch (ex) {
	daily_history = [];
}
rstats_busy = 0;
if (typeof(daily_history) == 'undefined') {
	daily_history = [];
	rstats_busy = 1;
}

var weeks = ['<% translate("Sunday"); %>', '<% translate("Monday"); %>', '<% translate("Tuesday"); %>', '<% translate("Wednesday"); %>', '<% translate("Thursday"); %>', '<% translate("Friday"); %>', '<% translate("Saturday"); %>'];
var weeksShort = ['<% translate("Sun"); %>', '<% translate("Mon"); %>', '<% translate("Tue"); %>', '<% translate("Wed"); %>', '<% translate("Thu"); %>', '<% translate("Fri"); %>', '<% translate("Sat"); %>'];
var startwk = 0;
var summary = 1;

function save()
{
	cookie.set('weekly', scale + ',' + startwk + ',' + summary, 31);
}

function changeStart(e)
{
	startwk = e.value * 1;
	redraw();
	save();
}

function changeMode(e)
{
	summary = e.value * 1;
	redraw();
	save();
}

function nth(n)
{
	n += '';
	switch (n.substr(n.length - 1, 1)) {
	case '1':
		return n + '<% translate("st"); %>';
	case '2':
		return n + '<% translate("nd"); %>';
	case '3':
		return n + '<% translate("rd"); %>';
	}
	return n + '<% translate("th"); %>';
}

function redraw()
{
	var h;
	var grid;
	var block;
	var rows;
	var dend;
	var dbeg;
	var dl, ul;
	var d, diff, ds;
	var tick, lastSplit;
	var yr, mo, da, wk;
	var gn;
	var swk;

	rows = 0;
	block = [];
	gn = 0;
	w = 0;
	lastSplit = 0;
	ul = dl = 0;
	dend = dbeg = '';

	swk	= startwk - 1;
	if (swk < 0) swk = 6;

	if (summary) {
		grid = '<table class="bwmg" cellspacing="1">';
		grid += makeRow('header', '<% translate("Date"); %>', '<% translate("Downloaded"); %>', '<% translate("Uploaded"); %>', '<% translate("Total"); %>');
	}
	else {
		grid = '';
	}

	function flush_block()
	{
		grid += '<b>' + dbeg + ' to ' + dend + '</b>' +
				'<table class="bwmg" cellspacing="1">' +
				makeRow('header', '<% translate("Date"); %>', '<% translate("Downloaded"); %>', '<% translate("Uploaded"); %>', '<% translate("Total"); %>') +
				block.join('') +
				makeRow('footer', '<% translate("Total"); %>', rescale(dl), rescale(ul), rescale(dl + ul)) +
				'</table><br>';
	}

	for (i = 0; i < daily_history.length; ++i) {
		h = daily_history[i];
		yr = (((h[0] >> 16) & 0xFF) + 1900);
		mo = ((h[0] >>> 8) & 0xFF);
		da = (h[0] & 0xFF);
		d = new Date(yr, mo, da);
		wk = d.getDay();

		tick = d.getTime();
		diff = lastSplit - tick;

		ds = ymdText(yr, mo, da) + ' <small>(' + weeksShort[wk] + ')</small>';

/*	REMOVE-BEGIN

	Jan 2007
	SU MO TU WE TH FR SA
	   01 02 03 04 05 06
	07 08 09 10 11 12 13
	14 15 16 17 18 19 20
	21 22 23 24 25 26 27
	28 29 30 31

	Feb 2007
	SU MO TU WE TH FR SA
	            01 02 03
	04 05 06 07 08 09 10
	11 12 13 14 15 16 17
	18 19 20 21 22 23 24
	25 26 27 28

	Mar 2007
	SU MO TU WE TH FR SA
	            01 02 03
	04 05 06 07 08 09 10
	11 12 13 14 15 16 17
	18 19 20 21 22 23 24
	25 26 27 28 29 30 31

	REMOVE-END */

		if ((wk == swk) || (diff >= (7 * 86400000)) || (lastSplit == 0)) {
			if (summary) {
				if (i > 0) {
					grid += makeRow(((rows & 1) ? 'odd' : 'even'),
						dend + '<br>' + dbeg, rescale(dl), rescale(ul), rescale(dl + ul));
					++rows;
					++gn;
				}
			}
			else {
				if (rows) {
					flush_block();
					++gn;
				}
				block = [];
				rows = 0;
			}
			dl = ul = 0;
			dend = ds;
			lastSplit = tick;
		}

		dl += h[1];
		ul += h[2];
		if (!summary) {
			block.unshift(makeRow(((rows & 1) ? 'odd' : 'even'), weeks[wk] + ' <small>' + (mo + 1) + '-' + da + '</small>', rescale(h[1]), rescale(h[2]), rescale(h[1] + h[2])))
			++rows;
		}

		dbeg = ds;
	}

	if (summary) {
		if (gn < 9) {
			grid += makeRow(((rows & 1) ? 'odd' : 'even'),
				dend + '<br>' + dbeg, rescale(dl), rescale(ul), rescale(dl + ul));
		}
		grid += '</table>';
	}
	else {
		if ((rows) && (gn < 9)) {
			flush_block();
		}
	}
	E('bwm-weekly-grid').innerHTML = grid;
}

function init()
{
	var s;

	if (nvram.rstats_enable != '1') {
		E('refresh-button').disabled = 1;
		return;
	}

	if ((s = cookie.get('weekly')) != null) {
		if (s.match(/^([0-2]),([0-6]),([0-1])$/)) {
			E('scale').value = scale = RegExp.$1 * 1;
			E('startwk').value = startwk = RegExp.$2 * 1
			E('shmode').value = summary = RegExp.$3 * 1;
		}
	}

	initDate('ymd');
	daily_history.sort(cmpHist);
	redraw();
}
</script>

</head>
<body onload='init()'>
<form>
<table id='container' cellspacing=0>
<tr><td colspan=2 id='header'>
	<div class='title'>Tomato</div>
	<div class='version'><% translate("Version"); %> <% version(); %></div>
</td></tr>
<tr id='body'><td id='navi'><script type='text/javascript'>navi()</script></td>
<td id='content'>
<div id='ident'><% ident(); %></div>

<!-- / / / -->

<div class='section-title'><% translate("WAN Bandwidth - Weekly"); %></div>
<div id='bwm-weekly-grid' style='float:left'></div>
<div style="float:right;text-align:right">
<b><% translate("Show"); %></b> <select onchange='changeMode(this)' id='shmode'><option value=1 selected><% translate("Summary"); %><option value=0><% translate("Full"); %></select><br>
<b><% translate("Date"); %></b> <select onchange='changeDate(this, "ymd")' id='dafm'><option value=0>yyyy-mm-dd</option><option value=1>mm-dd-yyyy</option><option value=2>mmm dd, yyyy</option><option value=3>dd.mm.yyyy</option></select><br>
<b><% translate("Week Start"); %></b> <select onchange='changeStart(this)' id='startwk'><option value=0 selected><% translate("Sun"); %><option value=1><% translate("Mon"); %><option value=2><% translate("Tue"); %><option value=3><% translate("Wed"); %><option value=4><% translate("Thu"); %><option value=5><% translate("Fri"); %><option value=6><% translate("Sat"); %></select><br>
<b><% translate("Scale"); %></b> <select onchange='changeScale(this)' id='scale'><option value=0>KB</option><option value=1>MB</option><option value=2 selected>GB</option></select><br>
<br>
&raquo; <a href="admin-bwm.asp"><% translate("Configure"); %></a>
<br><br><br>
</div>
<br>

<script type='text/javascript'>checkRstats();</script>

<!-- / / / -->

</td></tr>
<tr><td id='footer' colspan=2>
<input type='button' value='<% translate("Refresh"); %>' onclick='reloadPage()'>
</td></tr>
</table>
</form>
</body>
</html>
