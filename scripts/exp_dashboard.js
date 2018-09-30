$(document).ready(function() {
    $('#dashtabs').tabs();
    $('#subtabs').tabs();

    $( "#DECK_accordion" ).accordion({
	header: "h3",
	collapsible: true,
	active: false,
        heightStyle: "content"
      });
    $( "#MIP_accordion" ).accordion({
	header: "h3",
	collapsible: true,
	active: false,
        heightStyle: "content"
      });
    $( "#DCPP_accordion" ).accordion({
	header: "h3",
	collapsible: true,
	active: false,
        heightStyle: "content"
      });
    $( "#expDetail_accordion" ).accordion({
	header: "h3",
	collapsible: true,
	active: false,
        heightStyle: "content"
      });

    $("table th").css("background-color", "#CCCCCC");
    $("tr:odd").css("background-color", "#EEEEEED");

    $('.show-all-applying-DECK').click(function() {
        var text = $('.show-all-applying-DECK').text();
        if(text == 'show all'){
            $('.show-all-applying-DECK').text('hide all');
            $('.DECK_applying #DECK_accordion #DECK_table').slideDown("fast");
        }
        else{
            $('.show-all-applying-DECK').text('show all');
            $('.DECK_applying #DECK_accordion #DECK_table').slideUp("fast");
        }    
    });

    $('.show-all-applying-MIP').click(function() {
        var text = $('.show-all-applying-MIP').text();
        if(text == 'show all'){
            $('.show-all-applying-MIP').text('hide all');
            $('.MIP_applying #MIP_accordion #MIP_table').slideDown("fast");
        }
        else{
            $('.show-all-applying-MIP').text('show all');
            $('.MIP_applying #MIP_accordion #MIP_table').slideUp("fast");
        }    
    });

    $('.show-all-applying-DCPP').click(function() {
        var text = $('.show-all-applying-DCPP').text();
        if(text == 'show all'){
            $('.show-all-applying-DCPP').text('hide all');
            $('.DCPP_applying #DCPP_accordion #DCPP_table').slideDown("fast");
        }
        else{
            $('.show-all-applying-DCPP').text('show all');
            $('.DCPP_applying #DCPP_accordion #DCPP_table').slideUp("fast");
        }    
    });

    $('.show-all-exp-details').click(function() {
        var text = $('.show-all-exp-details').text();
        if(text == 'show all'){
            $('.show-all-exp-details').text('hide all');
            $('.expDetail_applying #expDetail_accordion #expDetail_table').slideDown("fast");
        }
        else{
            $('.show-all-exp-details').text('show all');
            $('.expDetail_applying #expDetail_accordion #expDetail_table').slideUp("fast");
        }    
    });

    $('#ProjectATable').DataTable( {
       "iDisplayLength": 100,
       "aLengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
     } );

    $('#ProjectBTable').DataTable( {
       "iDisplayLength": 100,
       "aLengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
     } );

    var table = $('#cmip6ExpTable').DataTable( {
	"responsive": true,
	"lengthMenu": [ [25, 50, -1], [25, 50, "All"] ],
	"order": [ [ 3, 'desc'], [ 0, 'asc'] ]
    } );

    // Handle click on "Expand All" button
    $('button#btn-show-all-children').on('click', function(){
	// Expand row details
	table.rows(':not(.parent)').nodes().to$().find('td:first-child').trigger('click');
    });

    // Handle click on "Collapse All" button
    $('button#btn-hide-all-children').on('click', function(){
	// Collapse row details
	table.rows('.parent').nodes().to$().find('td:first-child').trigger('click');
    });

    var statusTable = $('#statusTable').DataTable( {
	"responsive": true,
	"lengthMenu": [ [25, 50, -1], [25, 50, "All"] ],
	"order": [ [ 0, 'asc'] ]
    } );

    // Handle click on "Expand All" button
    $('button#statusBtn-show-all-children').on('click', function(){
	// Expand row details
	statusTable.rows(':not(.parent)').nodes().to$().find('td:first-child').trigger('click');
    });

    // Handle click on "Collapse All" button
    $('button#statusBtn-hide-all-children').on('click', function(){
	// Collapse row details
	statusTable.rows('.parent').nodes().to$().find('td:first-child').trigger('click');
    });

    var caseTable = $('#caseTable').DataTable( {
	"responsive": true,
	"lengthMenu": [ [25, 50, -1], [25, 50, "All"] ],
	"order": [ [ 0, 'asc'] ]
    } );

    // Handle click on "Expand All" button
    $('button#caseBtn-show-all-children').on('click', function(){
	// Expand row details
	caseTable.rows(':not(.parent)').nodes().to$().find('td:first-child').trigger('click');
    });

    // Handle click on "Collapse All" button
    $('button#caseBtn-hide-all-children').on('click', function(){
	// Collapse row details
	caseTable.rows('.parent').nodes().to$().find('td:first-child').trigger('click');
    });

    var diagsTable = $('#diagsTable').DataTable( {
	"responsive": true,
	"lengthMenu": [ [25, 50, -1], [25, 50, "All"] ],
	"order": [ [ 0, 'asc'] ]
    } );

    // Handle click on "Expand All" button
    $('button#diagsBtn-show-all-children').on('click', function(){
	// Expand row details
	diagsTable.rows(':not(.parent)').nodes().to$().find('td:first-child').trigger('click');
    });

    // Handle click on "Collapse All" button
    $('button#diagsBtn-hide-all-children').on('click', function(){
	// Collapse row details
	diagsTable.rows('.parent').nodes().to$().find('td:first-child').trigger('click');
    });

    $('#cesm2tuneTable').DataTable( {
       "iDisplayLength": 100,
       "aLengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
     } );

    $('#cesm2expTable').DataTable( {
       "iDisplayLength": 100,
       "aLengthMenu": [[25, 50, 100, -1], [25, 50, 100, "All"]],
     } );

});


