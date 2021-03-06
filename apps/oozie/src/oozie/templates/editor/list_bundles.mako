## Licensed to Cloudera, Inc. under one
## or more contributor license agreements.  See the NOTICE file
## distributed with this work for additional information
## regarding copyright ownership.  Cloudera, Inc. licenses this file
## to you under the Apache License, Version 2.0 (the
## "License"); you may not use this file except in compliance
## with the License.  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

<%!
  from desktop.views import commonheader, commonfooter
  from django.utils.translation import ugettext as _
  import time as py_time
%>

<%namespace name="actionbar" file="../actionbar.mako" />
<%namespace name="layout" file="../navigation-bar.mako" />
<%namespace name="utils" file="../utils.inc.mako" />

${ commonheader(_("Oozie App"), "oozie", user, "100px") | n,unicode }
${ layout.menubar(section='bundles') }


<div class="container-fluid">
  <h1>${ _('Bundle Manager') }</h1>

  <%actionbar:render>
    <%def name="actions()">
        <button class="btn toolbarBtn" id="submit-btn" disabled="disabled"><i class="icon-play"></i> ${ _('Submit') }</button>
        <button class="btn toolbarBtn" id="clone-btn" disabled="disabled"><i class="icon-retweet"></i> ${ _('Clone') }</button>
        <button class="btn toolbarBtn" id="delete-btn" disabled="disabled"><i class="icon-remove"></i> ${ _('Delete') }</button>
    </%def>

    <%def name="creation()">
        <a href="${ url('oozie:create_bundle') }" class="btn"><i class="icon-plus-sign"></i> ${ _('Create') }</a>
    </%def>
  </%actionbar:render>

  <table id="bundleTable" class="table datatables">
    <thead>
      <tr>
        <th width="1%"><div class="hueCheckbox selectAll" data-selectables="bundleCheck"></div></th>
        <th width="10%">${ _('Name') }</th>
        <th width="20%">${ _('Description') }</th>
        <th width="35%">${ _('Coordinators') }</th>
        <th>${ _('Kick off') }</th>
        <th>${ _('Status') }</th>
        <th>${ _('Last Modified') }</th>
        <th>${ _('Owner') }</th>
      </tr>
    </thead>
    <tbody>
      % for bundle in jobs:
        <tr>
          <td data-row-selector-exclude="true">
            <div class="hueCheckbox bundleCheck" data-row-selector-exclude="true"
              % if bundle.is_accessible(currentuser):
                  data-clone-url="${ url('oozie:clone_bundle', bundle=bundle.id) }"
                  data-submit-url="${ url('oozie:submit_bundle', bundle=bundle.id) }"
              % endif
              % if bundle.is_editable(currentuser):
                  data-delete-id="${ bundle.id }"
              % endif
              >
            </div>
            % if bundle.is_accessible(currentuser):
              <a href="${ url('oozie:edit_bundle', bundle=bundle.id) }" data-row-selector="true"/>
            % endif
          </td>
          <td>${ bundle.name }</td>
          <td>${ bundle.description }</td>
          <td>
             % for bundled in bundle.coordinators.all():
               ${ bundled.coordinator.name }
		       % if not loop.last:
		        ,
		       % endif
             % endfor
          </td>
          <td>${ bundle.kick_off_time }</td>
          <td>
            <span class="label label-info">${ bundle.status }</span>
          </td>
          <td nowrap="nowrap" data-sort-value="${py_time.mktime(bundle.last_modified.timetuple())}">${ utils.format_date(bundle.last_modified) }</td>
          <td>${ bundle.owner.username }</td>
        </tr>
      %endfor
    </tbody>
  </table>
</div>


<div id="submit-job-modal" class="modal hide"></div>

<div id="delete-job" class="modal hide">
  <form id="deleteWfForm" action="${ url('oozie:delete_bundle') }" method="POST">
    <div class="modal-header">
      <a href="#" class="close" data-dismiss="modal">&times;</a>
      <h3 id="deleteWfMessage">${ _('Delete the selected bundle(s)?') }</h3>
    </div>
    <div class="modal-footer">
      <a href="#" class="btn" data-dismiss="modal">${ _('No') }</a>
      <input type="submit" class="btn btn-danger" value="${ _('Yes') }"/>
    </div>
    <div class="hide">
      <select name="job_selection" data-bind="options: availableJobs, selectedOptions: chosenJobs" size="5" multiple="true"></select>
    </div>
  </form>
</div>

<script src="/static/ext/js/datatables-paging-0.1.js" type="text/javascript" charset="utf-8"></script>
<script src="/static/ext/js/knockout-2.1.0.js" type="text/javascript" charset="utf-8"></script>

<script type="text/javascript" charset="utf-8">
  $(document).ready(function () {
    var viewModel = {
        availableJobs : ko.observableArray(${ json_jobs | n }),
        chosenJobs : ko.observableArray([])
    };

    ko.applyBindings(viewModel);

    $(".selectAll").click(function () {
      if ($(this).attr("checked")) {
        $(this).removeAttr("checked").removeClass("icon-ok");
        $("." + $(this).data("selectables")).removeClass("icon-ok").removeAttr("checked");
      }
      else {
        $(this).attr("checked", "checked").addClass("icon-ok");
        $("." + $(this).data("selectables")).addClass("icon-ok").attr("checked", "checked");
      }
      toggleActions();
    });

    $(".bundleCheck").click(function () {
      if ($(this).attr("checked")) {
        $(this).removeClass("icon-ok").removeAttr("checked");
      }
      else {
        $(this).addClass("icon-ok").attr("checked", "checked");
      }
      $(".selectAll").removeAttr("checked").removeClass("icon-ok");
      toggleActions();
    });

    function toggleActions() {
      $(".toolbarBtn").attr("disabled", "disabled");
      var selector = $(".hueCheckbox[checked='checked']");
      if (selector.length == 1) {
        var action_buttons = [
          ['#submit-btn', 'data-submit-url'],
          ['#bundle-btn', 'data-bundle-url'],
          ['#clone-btn', 'data-clone-url']
        ];
        $.each(action_buttons, function (index) {
          if (selector.attr(this[1])) {
            $(this[0]).removeAttr("disabled");
          } else {
            $(this[0]).attr("disabled", "disabled");
          }
        });
      }
      var can_delete = $(".hueCheckbox[checked='checked'][data-delete-id]");
      if (can_delete.length >= 1 && can_delete.length == selector.length) {
        $("#delete-btn").removeAttr("disabled");
      }
    }

    $("#delete-btn").click(function (e) {
      viewModel.chosenJobs.removeAll();
      $(".hueCheckbox[checked='checked']").each(function( index ) {
        viewModel.chosenJobs.push($(this).data("delete-id"));
      });
      $("#delete-job").modal("show");
    });

    $("#submit-btn").click(function () {
      var _this = $(".hueCheckbox[checked='checked']");
      var _action = _this.attr("data-submit-url");
      $.get(_action, function (response) {
          $("#submit-job-modal").html(response);
          $("#submit-job-modal").modal("show");
        }
      );
    });

    $(".deleteConfirmation").click(function () {
      var _this = $(this);
      var _action = _this.attr("data-url");
      $("#deleteWfForm").attr("action", _action);
      $("#deleteWfMessage").text(_this.attr("alt"));
      $("#delete-job").modal("show");
    });

    $("#clone-btn").click(function (e) {
      var _this = $(".hueCheckbox[checked='checked']");
      var _url = _this.attr("data-clone-url");
      $.post(_url, function (data) {
        window.location = data.url;
      });
    });

    var oTable = $("#bundleTable").dataTable({
      "sPaginationType":"bootstrap",
      'iDisplayLength':50,
      "bLengthChange":false,
      "sDom":"<'row'r>t<'row'<'span8'i><''p>>",
      "aoColumns":[
        { "bSortable":false },
        null,
        null,
        null,
        null,
        { "sSortDataType":"dom-sort-value", "sType":"numeric" },
        null,
        null
      ],
      "aaSorting":[
        [ 6, "desc" ]
      ],
      "oLanguage":{
        "sEmptyTable":"${_('No data available')}",
        "sInfo":"${_('Showing _START_ to _END_ of _TOTAL_ entries')}",
        "sInfoEmpty":"${_('Showing 0 to 0 of 0 entries')}",
        "sInfoFiltered":"${_('(filtered from _MAX_ total entries)')}",
        "sZeroRecords":"${_('No matching records')}",
        "oPaginate":{
          "sFirst":"${_('First')}",
          "sLast":"${_('Last')}",
          "sNext":"${_('Next')}",
          "sPrevious":"${_('Previous')}"
        }
      }
    });

    $("#filterInput").keydown(function (e) {
      if (e.which == 13) {
        e.preventDefault();
        return false;
      }
    });

    $("#filterInput").keyup(function () {
      oTable.fnFilter($(this).val());
    });

    $("a[data-row-selector='true']").jHueRowSelector();
  });
</script>

${ commonfooter(messages) | n,unicode }
