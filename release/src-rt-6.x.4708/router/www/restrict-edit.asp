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
<title>[<% ident(); %>] <% translate("Edit Access Restrictions"); %></title>
<link rel='stylesheet' type='text/css' href='tomato.css'>
<link rel='stylesheet' type='text/css' href='color.css'>
<script type='text/javascript' src='tomato.js'></script>
<script type='text/javascript' src='protocols.js'></script>

<!-- / / / -->

<style type='text/css'>
#res-comp-grid {
	width: 60%;
}
#res-bp-grid .box1, #res-bp-grid .box2 {
	width: 20%;
	float: left;
}
#res-bp-grid .box3 {
	width: 60%;
	float: left;
}
#res-bp-grid .box4 {
	width: 30%;
	float: left;
	clear: left;
	padding-top: 2px;
}
#res-bp-grid .box5 {
	width: 70%;
	float: left;
	padding-top: 2px;
}
#res-bp-grid .box6 {
	width: 30%;
	float: left;
	padding-top: 2px;
}
#res-bp-grid .box7 {
	width: 70%;
	float: left;
	padding-top: 2px;
}

textarea {
	width: 99%;
	height: 20em;
}
</style>

<script type='text/javascript' src='debug.js'></script>

<script type='text/javascript'>
//	<% nvram(''); %>	// http_id

// {enable}|{begin_mins}|{end_mins}|{dow}|{comp[<comp]}|{rules<rules[...]>}|{http[ ...]}|{http_file}|{desc}
//	<% rrule(); %>
if ((rule = rrule.match(/^(\d+)\|(-?\d+)\|(-?\d+)\|(\d+)\|(.*?)\|(.*?)\|([^|]*?)\|(\d+)\|(.*)$/m)) == null) {
	rule = ['', 1, 1380, 240, 31, '', '', '', 0, '<% translate("New Rule"); %> ' + (rruleN + 1)];
}
rule[2] *= 1;
rule[3] *= 1;
rule[4] *= 1;
rule[8] *= 1;

// <% layer7(); %>
layer7.sort();
for (i = 0; i < layer7.length; ++i)
	layer7[i] = [layer7[i],layer7[i]];
layer7.unshift(['', 'Layer 7 (<% translate("disabled"); %>)']);

var ipp2p = [
	[0,'IPP2P (<% translate("disabled"); %>)'],[0xFFFF,'<% translate("All IPP2P Filters"); %>'],[1,'<% translate("AppleJuice"); %>'],[2,'<% translate("Ares"); %>'],[4,'<% translate("BitTorrent"); %>'],[8,'<% translate("Direct Connect"); %>'],
	[16,'<% translate("eDonkey"); %>'],[32,'<% translate("Gnutella"); %>'],[64,'<% translate("Kazaa"); %>'],[128,'<% translate("Mute"); %>'],
/* LINUX26-BEGIN */
	[4096,'<% translate("PPLive/UUSee"); %>'],
/* LINUX26-END */
	[256,'<% translate("SoulSeek"); %>'],[512,'<% translate("Waste"); %>'],[1024,'<% translate("WinMX"); %>'],[2048,'<% translate("XDCC"); %>']
/* LINUX26-BEGIN */
	,[8192,'<% translate("Xunlei/QQCyclone"); %>']
/* LINUX26-END */
	];
// array MUST be in English
var dowNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

var cg = new TomatoGrid();

cg.verifyFields = function(row, quiet) {
	var f = fields.getAll(row)[0];
	if (v_mac(f, true)) return true;
	if (_v_iptaddr(f, true, false, true, true)) return true;

	ferror.set(f, '<% translate("Invalid MAC address or IP address/range"); %>', quiet);
	return false;
}

cg.setup = function() {
	var a, i, count, ex;

	this.init('res-comp-grid', 'sort', 140, [ { type: 'text', maxlen: 32 } ] );
	this.headerSet(['<% translate("MAC / IP Address"); %>']);
	this.showNewEditor();
	this.resetNewEditor();

	if (rule[5] == '~') return;	// wireless disable rule

	ex = 0;
	count = 0;
	a = rule[5].split('>');
	for (i = 0; i < a.length; ++i) {
		if (!a[i].length) continue;
		if (a[i] == '!') {
			ex = 1;
		}
		else {
			cg.insertData(-1, [a[i]]);
			++count;
		}
	}

	a = E('_f_comp_all')
	if (count) {
		a.value = ex ? 2 : 1;
	}
	else {
		a.value = 0;
	}
}


var bpg = new TomatoGrid();

bpg.verifyFields = function(row, quiet) {
	var f = fields.getAll(row);
	ferror.clearAll(f);
	this.enDiFields(row);

	if ((f[5].selectedIndex != 0) && ((!v_length(f[6], quiet, 1)) || (!_v_iptaddr(f[6], quiet, false, true, true)))) return 0;
	if ((f[1].selectedIndex != 0) && (!v_iptport(f[2], quiet))) return 0;

	if ((f[1].selectedIndex == 0) && (f[3].selectedIndex == 0) && (f[4].selectedIndex == 0) && (f[5].selectedIndex == 0)) {
		var m = '<% translate("Please enter a specific address or port, or select an application match"); %>';
		ferror.set(f[3], m, 1);
		ferror.set(f[4], m, 1);
		ferror.set(f[5], m, 1);
		ferror.set(f[1], m, quiet);
		return 0;
	}

	ferror.clear(f[1]);
	ferror.clear(f[3]);
	ferror.clear(f[4]);
	ferror.clear(f[5]);
	ferror.clear(f[6]);
	return 1;
}

bpg.dataToView = function(data) {
	var s, i;

	s = '';
	if (data[5] != 0) s = ((data[5] == 1) ? '<% translate("To"); %> ' : '<% translate("From"); %> ') + data[6] + ', ';

	if (data[0] <= -2) s += (s.length ? 'a' : 'A') + 'ny protocol';
	else if (data[0] == -1) s += '<% translate("TCP/UDP"); %>';
	else if (data[0] >= 0) s += protocols[data[0]] || data[0];

	if (data[0] >= -1) {
		if (data[1] == 'd') s += ', <% translate("dst port"); %> ';
		else if (data[1] == 's') s += ', <% translate("src port"); %> ';
		else if (data[1] == 'x') s += ', <% translate("port"); %> ';
		else s += ', <% translate("all ports"); %>';
		if (data[1] != 'a') s += data[2].replace(/:/g, '-');
	}

	if (data[3] != 0) {
		for (i = 0; i < ipp2p.length; ++i) {
			if (data[3] == ipp2p[i][0]) {
				s += ', <% translate("IPP2P"); %>: ' + ipp2p[i][1];
				break;
			}
		}
	}
	else if (data[4] != '') {
		s += ', <% translate("L7"); %>: ' + data[4];
	}

	return [s];
}

bpg.fieldValuesToData = function(row) {
	var f = fields.getAll(row);
	return [f[0].value, f[1].value, (f[1].selectedIndex == 0) ? '' : f[2].value, f[3].value, f[4].value, f[5].value, (f[5].selectedIndex == 0) ? '' : f[6].value];
},

bpg.resetNewEditor = function() {
	var f = fields.getAll(this.newEditor);
	f[0].selectedIndex = 0;
	f[1].selectedIndex = 0;
	f[2].value = '';
	f[3].selectedIndex = 0;
	f[4].selectedIndex = 0;
	f[5].selectedIndex = 0;
	f[6].value = '';
	this.enDiFields(this.newEditor);
	ferror.clearAll(fields.getAll(this.newEditor));
}

bpg._createEditor = bpg.createEditor;
bpg.createEditor = function(which, rowIndex, source) {
	var row = this._createEditor(which, rowIndex, source);
	if (which == 'edit') this.enDiFields(row);
	return row;
}

bpg.enDiFields = function(row) {
	var x;
	var f = fields.getAll(row);

	x = f[0].value;
	x = ((x != -1) && (x != 6) && (x != 17));
	f[1].disabled = x;
	if (f[1].selectedIndex == 0) x = 1;
	f[2].disabled = x;
	f[3].disabled = (f[4].selectedIndex != 0);
	f[4].disabled = (f[3].selectedIndex != 0);
	f[6].disabled = (f[5].selectedIndex == 0);
}

bpg.setup = function() {
	var a, i, r, count, protos;

	protos = [[-2, '<% translate("Any Protocol"); %>'],[-1,'<% translate("TCP/UDP"); %>'],[6,'<% translate("TCP"); %>'],[17,'<% translate("UDP"); %>']];
	for (i = 0; i < 256; ++i) {
		if ((i != 6) && (i != 17)) protos.push([i, protocols[i] || i]);
	}

	this.init('res-bp-grid', 'sort', 140, [ { multi: [
		{ type: 'select', prefix: '<div class="box1">', suffix: '</div>', options: protos },
		{ type: 'select', prefix: '<div class="box2">', suffix: '</div>',
			options: [['a','<% translate("Any Port"); %>'],['d','<% translate("Dst Port"); %>'],['s','<% translate("Src Port"); %>'],['x','<% translate("Src or Dst"); %>']] },
		{ type: 'text', prefix: '<div class="box3">', suffix: '</div>', maxlen: 32 },
		{ type: 'select', prefix: '<div class="box4">', suffix: '</div>', options: ipp2p },
		{ type: 'select', prefix: '<div class="box5">', suffix: '</div>', options: layer7 },
		{ type: 'select', prefix: '<div class="box6">', suffix: '</div>',
			options: [[0,'<% translate("Any Address"); %>'],[1,'<% translate("Dst IP"); %>'],[2,'<% translate("Src IP"); %>']] },
		{ type: 'text', prefix: '<div class="box7">', suffix: '</div>', maxlen: 64 }
		] } ] );
	this.headerSet(['<% translate("Rules"); %>']);
	this.showNewEditor();
	this.resetNewEditor();
	count = 0;

	// ---- proto<dir<port<ipp2p<layer7[<addr_type<addr]

	a = rule[6].split('>');
	for (i = 0; i < a.length; ++i) {
		r = a[i].split('<');
		if (r.length == 5) {
			// ---- fixup for backward compatibility
			r.push('0');
			r.push('');
		}
		if (r.length == 7) {
			r[2] = r[2].replace(/:/g, '-');
			this.insertData(-1, r);
			++count;
		}
	}
	return count;
}

//

function verifyFields(focused, quiet)
{
	var b, e;

	tgHideIcons();

	elem.display(PR('_f_sched_begin'), !E('_f_sched_allday').checked);
	elem.display(PR('_f_sched_sun'), !E('_f_sched_everyday').checked);

	b = E('rt_norm').checked;
	elem.display(PR('_f_comp_all'), PR('_f_block_all'), b);

	elem.display(PR('res-comp-grid'), b && E('_f_comp_all').value != 0);
	elem.display(PR('res-bp-grid'), PR('_f_block_http'), PR('_f_activex'), b && !E('_f_block_all').checked);

	ferror.clear('_f_comp_all');

	e = E('_f_block_http');
	e.value = e.value.replace(/[|"']/g, ' ');
	if (!v_length(e, quiet, 0, 2048 - 16)) return 0;

	e = E('_f_desc');
	e.value = e.value.replace(/\|/g, '_');
	if (!v_length(e, quiet, 1)) return 0;

	return 1;
}

function cancelRule()
{
	document.location = 'restrict.asp';
}

function removeRule()
{
	if (!confirm('<% translate("Delete this rule?"); %>')) return;

	E('delete-button').disabled = 1;

	e = E('_rrule');
	e.name = 'rrule' + rruleN;
	e.value = '';
	form.submit('_fom');
}

function saveRule()
{
	if (!verifyFields(null, false)) return;
	if ((cg.isEditing()) || (bpg.isEditing())) return;

	var a, b, e, s, n, data;

	data = [];
	data.push(E('_f_enabled').checked ? '1' : '0');
	if (E('_f_sched_allday').checked) data.push(-1, -1);
		else data.push(E('_f_sched_begin').value, E('_f_sched_end').value);

	if (E('_f_sched_everyday').checked) {
		n = 0x7F;
	}
	else {
		n = 0;
		for (i = 0; i < 7; ++i) {
			if (E('_f_sched_' + dowNames[i].toLowerCase()).checked) n |= (1 << i);
		}
		if (n == 0) n = 0x7F;
	}
	data.push(n);

	if (E('rt_norm').checked) {
		e = E('_f_comp_all');
		if (e.value != 0) {
			a = cg.getAllData();
			if (a.length == 0) {
				ferror.set(e, '<% translate("No MAC or IP address was specified"); %>', 0);
				return;
			}
			if (e.value == 2) a.unshift('!');
			data.push(a.join('>'));
		}
		else {
			data.push('');
		}

		if (E('_f_block_all').checked) {
			data.push('', '', '0');
		}
		else {
			var check = 0;
			a = bpg.getAllData();
			check += a.length;
			b = [];
			for (i = 0; i < a.length; ++i) {
				a[i][2] = a[i][2].replace(/-/g, ':');
				b.push(a[i].join('<'));
			}
			data.push(b.join('>'));

			a = E('_f_block_http').value.replace(/\r+/g, ' ').replace(/\n+/g, '\n').replace(/ +/g, ' ').replace(/^\s+|\s+$/g, '');
			check += a.length;
			data.push(a);

			n = 0;
			if (E('_f_activex').checked) n = 1;
			if (E('_f_flash').checked) n |= 2;
			if (E('_f_java').checked) n |= 4;
			data.push(n);
			
			if (((check + n) == 0) && (data[0] == 1)) {
				alert('<% translate("Please specify what items should be blocked"); %>.');
				return;
			}
		}
	}
	else {
		data.push('~');
		data.push('', '', '', '0');
	}

	data.push(E('_f_desc').value);
	data = data.join('|');

	if (data.length >= 2048) {
		alert('<% translate("This rule is too big. Please reduce by"); %> ' + (data.length - 2048) + ' <% translate("characters"); %>.');
		return;
	}

	e = E('_rrule');
	e.name = 'rrule' + rruleN;
	e.value = data;

	E('delete-button').disabled = 1;
	form.submit('_fom');
}

function init()
{
	cg.recolor();
	bpg.recolor();
}

function earlyInit()
{
	var count;

	cg.setup();

	count = bpg.setup();
	E('_f_block_all').checked = (count == 0) && (rule[7].search(/[^\s\r\n]/) == -1) && (rule[8] == 0);
	verifyFields(null, 1);
}
</script>
</head>
<body onload='init()'>
<form name='_fom' id='_fom' method='post' action='tomato.cgi'>
<table id='container' cellspacing=0>
<tr><td colspan=2 id='header'>
	<div class='title'>Tomato</div>
	<div class='version'><% translate("Version"); %> <% version(); %></div>
</td></tr>
<tr id='body'><td id='navi'><script type='text/javascript'>navi()</script></td>
<td id='content'>
<div id='ident'><% ident(); %></div>

<!-- / / / -->

<input type='hidden' name='_nextpage' value='restrict.asp'>
<input type='hidden' name='_service' value='restrict-restart'>
<input type='hidden' name='rruleNN' id='_rrule' value=''>

<div class='section-title'><% translate("Access Restriction"); %></div>
<div class='section'>
<script type='text/javascript'>
W('<div style="float:right"><small>'+ 'ID: ' + rruleN.pad(2) + '</small>&nbsp;</div><br>');
tm = [];
for (i = 0; i < 1440; i += 15) tm.push([i, timeString(i)]);

createFieldTable('', [
	{ title: '<% translate("Enabled"); %>', name: 'f_enabled', type: 'checkbox', value: rule[1] == '1' },
	{ title: '<% translate("Description"); %>', name: 'f_desc', type: 'text', maxlen: 32, size: 35, value: rule[9] },
	{ title: '<% translate("Schedule"); %>', multi: [
		{ name: 'f_sched_allday', type: 'checkbox', suffix: ' <% translate("All Day"); %> &nbsp; ', value: (rule[2] < 0) || (rule[3] < 0) },
		{ name: 'f_sched_everyday', type: 'checkbox', suffix: ' <% translate("Everyday"); %>', value: (rule[4] & 0x7F) == 0x7F } ] },
	{ title: '<% translate("Time"); %>', indent: 2, multi: [
		{ name: 'f_sched_begin', type: 'select', options: tm, value: (rule[2] < 0) ? 0 : rule[2], suffix: ' - ' },
		{ name: 'f_sched_end', type: 'select', options: tm, value: (rule[3] < 0) ? 0 : rule[3] } ] },
	{ title: '<% translate("Days"); %>', indent: 2, multi: [
		{ name: 'f_sched_mon', type: 'checkbox', suffix: ' <% translate("Mon"); %> &nbsp; ', value: (rule[4] & (1 << 1)) },
		{ name: 'f_sched_tue', type: 'checkbox', suffix: ' <% translate("Tue"); %> &nbsp; ', value: (rule[4] & (1 << 2)) },
		{ name: 'f_sched_wed', type: 'checkbox', suffix: ' <% translate("Wed"); %> &nbsp; ', value: (rule[4] & (1 << 3)) },
		{ name: 'f_sched_thu', type: 'checkbox', suffix: ' <% translate("Thu"); %> &nbsp; ', value: (rule[4] & (1 << 4)) },
		{ name: 'f_sched_fri', type: 'checkbox', suffix: ' <% translate("Fri"); %> &nbsp; ', value: (rule[4] & (1 << 5)) },
		{ name: 'f_sched_sat', type: 'checkbox', suffix: ' <% translate("Sat"); %> &nbsp; ', value: (rule[4] & (1 << 6)) },
		{ name: 'f_sched_sun', type: 'checkbox', suffix: ' <% translate("Sun"); %> &nbsp; ', value: (rule[4] & 1) }
		] },
	{ title: '<% translate("Type"); %>', name: 'f_type', id: 'rt_norm', type: 'radio', suffix: ' <% translate("Normal Access Restriction"); %>', value: (rule[5] != '~') },
	{ title: '', name: 'f_type', id: 'rt_wl', type: 'radio', suffix: ' <% translate("Disable Wireless"); %>', value: (rule[5] == '~') },
	{ title: '<% translate("Applies To"); %>', name: 'f_comp_all', type: 'select', options: [[0,'<% translate("All Computers / Devices"); %>'],[1,'<% translate("The Following"); %>...'],[2,'<% translate("All Except"); %>...']], value: 0 },
	{ title: '&nbsp;', text: '<table class="tomato-grid" cellspacing=1 id="res-comp-grid"></table>' },
	{ title: '<% translate("Blocked Resources"); %>', name: 'f_block_all', type: 'checkbox', suffix: ' <% translate("Block All Internet Access"); %>', value: 0 },
	{ title: '<% translate("Port"); %> /<br><% translate("Application"); %>', indent: 2, text: '<table class="tomato-grid" cellspacing=1 id="res-bp-grid"></table>' },
	{ title: '<% translate("HTTP Request"); %>', indent: 2, name: 'f_block_http', type: 'textarea', value: rule[7] },
	{ title: '<% translate("HTTP Requested Files"); %>', indent: 2, multi: [
		{ name: 'f_activex', type: 'checkbox', suffix: ' <% translate("ActiveX (ocx, cab)"); %> &nbsp;&nbsp;', value: (rule[8] & 1) },
		{ name: 'f_flash', type: 'checkbox', suffix: ' <% translate("Flash (swf)"); %> &nbsp;&nbsp;', value: (rule[8] & 2) },
		{ name: 'f_java', type: 'checkbox', suffix: ' <% translate("Java (class, jar)"); %> &nbsp;&nbsp;', value: (rule[8] & 4) } ] }
]);
</script>
</div>

<!-- / / / -->

</td></tr>
<tr><td id='footer' colspan=2>
	<span id='footer-msg'></span>
	<input type='button' value='<% translate("Delete"); %>...' id='delete-button' onclick='removeRule()'>
	&nbsp;
	<input type='button' value='<% translate("Save"); %>' id='save-button' onclick='saveRule()'>
	<input type='button' value='<% translate("Cancel"); %>' id='cancel-button' onclick='cancelRule()'>
</td></tr>
</table>
<br><br>
</form>
<script type='text/javascript'>earlyInit();</script>
</body>
</html>