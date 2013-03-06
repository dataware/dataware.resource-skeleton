<!-- HEADER ------------------------------------------------------------------->
%include header user=user

<script>
$(function(){
    var rm = new ResourceModel();
    rm.loadResources({{!resources}});
    ko.applyBindings(rm, $(".mydata")[0]);
     
  });
</script>

<div class="container">

    <div class="well">
        <h1>Welcome to the resource manager.<small> Browse and manage your data resources </small></h1>
    </div>
    
    %if user:
    <div class="mydata">     
        <div class="row">
            <div class="span10">
                <ul class="nav nav-pills" data-bind="foreach:resources">
                    <li data-bind="css:{active: $parent.amActive(resource_name())}">
                        <a data-bind="attr:{href: '#' + resource_name()}, click:function(){$parent.selectedResource($data);}, text:resource_name"></a>
                   </li>
                </ul>
            </div>
            
            <div class="span2">
                <ul class="nav nav-pills">
                    <li> <a href="#" data-bind="click:function(){ resourceDialog();}"> + </a> </li>
                </ul>
            </div>
    	</div>
    	
        <div class="row">
            <div class="span10">
                        
                <div data-bind="if: selectedResource().installed() == 0">
                    <div class="alert alert-info">
                        <a data-bind="attr:{href:selectedResource().install_url}">Share your data</a>
                    </div>
                </div>
                

               <div data-bind="if: selectedResource().installed() == 1">
                  <div class="alert alert-success">
                  You are sharing this data with <a data-bind="attr:{href:selectedResource().catalog_uri()}"> <strong> <span data-bind="text:selectedResource().catalog_uri()"></span></strong></a>
                  </div>
               </div>        
             </div>
        </div>
        <div class="row">
            <div class="span10">
                <div class="myview"></div>
            </div>
        </div>
        
    </div>
	%end
</div>

            <div class="wizard" id="some-wizard">
            
                <h1>Add a new resource</h1>
                
                <div class="wizard-card" data-cardname="card1">
                    <h3>Chose Entity</h3>
                    <select data-bind="options:entities, value:currentEntity"></select>
                </div>
                
                <div class="wizard-card" data-cardname="card2">
                    <h3>Data source</h3>
                    <label> Select data source </label>
                    <select data-bind="options:sources, value:currentSource"></select>
                </div>
                
                <div class="wizard-card" data-cardname="card3">
                    <h3>Filter</h3>
                    <table class="table table-striped table-bordered">
                        <thead>
                            <tr>
                                <th>column</th>
                                <th>type</th>
                                <th>select</th>
                            </tr>
                        </thead>
                        <tbody data-bind="foreach:schema">
                            <tr>
                                <td> <span data-bind="text:column_name"> </span></td>
                                <td> <span data-bind="text:data_type"> </span></td>
                                <td> <input type="checkbox" data-bind="attr:{value:column_name}, checked:$parent.selectedColumns"/></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                
                <div class="wizard-card" data-cardname="card4">
                    <h3>Describe it</h3>
                        
                        <label>Resource name</label>
                       <input type="text" placeholder="Resource name">
                        <span class="help-block">The (unique) name for this resource</span>
                        
                        <label>Resource description</label>
                        <textarea rows="5" class="span6"></textarea>
                        <span class="help-block">Give as much information as you can about this resource</span>
                </div>
                
                <div class="wizard-card" data-cardname="card5">
                    <h3>Visualise it</h3>
                    <label>Choose visualization type</label>
                    <select data-bind="options:chartTypes, value:currentType"></select>
                    
                </div>
            </div>
        
<!-- FOOTER ------------------------------------------------------------------>
%include footer
