<html>
<head>
<title>My dataware resources</title>

<!--<link rel="stylesheet" type="text/css" href="./static/jqcloud.css" />-->
<link rel="stylesheet" type="text/css" href="./static/bootstrap/css/bootstrap.css" /> 
<link rel="stylesheet" type="text/css" href="./static/bootstrap-wizard/src/bootstrap-wizard.css" />
<link rel="stylesheet" type="text/css" href="./static/bootstrap-notify/css/bootstrap-notify.css" />


<script type="text/javascript" src="./static/jquery/jquery-1.8.2.min.js"></script>
<script type="text/javascript" src="./static/jquery/jquery-ui-1.8.23.min.js"></script>
<script type="text/javascript" src="./static/knockout/knockout-2.1.0.js"></script>
<script type="text/javascript" src="./static/knockout/knockout-postbox.min.js"></script>
<script type="text/javascript" src="./static/knockout/knockout-mapping.js"></script>
<script type="text/javascript" src="./static/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="./static/bootstrap-notify/js/bootstrap-notify.js"></script>
<script type="text/javascript" src="./static/bootstrap-wizard/src/bootstrap-wizard.js"></script>
<script type="text/javascript" src="http://www.google.com/jsapi"></script>
<script type="text/javascript" src="./static/d3/d3.min.js"></script>


<style>
    input[type="text"]{
        height: 30px;
    }
    .chart{
        margin-top: 20px;
    }
</style>


<script>
    var NotificationModel = function(){
        
        var self = this;
        
        this.events = ko.observableArray([]);
        
        this.lastEvent = ko.observable("").publishOn("myevents");
         
        /*
         * subscribe to the events observable array and publish the last
         * element, to be viewed by other view models.  Note that this currently
         * sends a reference.  To create a deep copy we could do ko.toJSON and recreate
         * at the other end.
         */
        this.events.subscribe(function(newValue){
            this.lastEvent(this.events()[this.events().length -1]);
        },this);
        
        
        this.read = function(message){
            self.events.remove(message);
        };
        
        this.startpolling = function(frequency){
            
            setTimeout(function(){
        
                $.ajax({
                    url: "/stream",
                    dataType: 'json', 
                    timeout: 30000,
                    cache: false,
                    
                    success: function(data) {
                        frequency = 500;
                       
                        self.events.push(data);
                       
                        $('.top-right').notify({
                            message: { text: data.message }
                        }).show();
                    },
                     
                    error: function(XMLHttpRequest, textStatus, errorThrown){
                        switch(XMLHttpRequest.status){
                            case 502: //update server is down
                            case 403: //forbidden - unlikely to get access anytime soon
                                frequency = 60000;
                                break; 
                            default:
                                frequency = 500;
                        }
                    },
                    
                    complete: function(){
                        self.startpolling(frequency);        
                    }
                });
            
            },frequency);
        }
    }
</script>


<script>


 function barchart(){
 
        var that = {};
        
        that.chart;
        
        that.visible   = ko.observable(false);
        
        that.topmargin = ko.observable("margin-top: 0px");
        
        var format_data  = function(options){
            
            var label, value, max, min;
            
            if (options.xtype == "numeric"){
                label = options.y;
                value = options.x;
            }else{
                label = options.x;
                value = options.y;
            }
            
            max = min = options.data[0][value];
           
            values = ko.utils.arrayMap(options.data, function(item){
                max = Math.max(max, item[value]);
                min = Math.min(min, item[value]);
                return {"label": item[label], "value":item[value]};
            }); 
            
            return {'values': values, 'max': max, 'min':min}
            
        }
        
        var create_scale = function(min, max, orientation, width, height, padding){
            return  d3.scale.linear()
                    .domain([min,max])
                    .range([0, orientation == 1 ? (height-padding) : (width-padding)]);
        };
        
        var bar_width = function(orientation, width, height, padding, length){
            return orientation == 1 ? (width - (2*padding)) / length 
                                    : (height-(2*padding)) / length;
        }
        
        var bar_y = function(scale, barWidth, height, padding, orientation){
            return  function(datum, index){
                if (orientation == 1)
                    return height - scale(datum.value);
                else
                    return padding + (index * barWidth); 
            }
        }
          
        var bar_x = function(barWidth, padding, orientation){
            return function(datum, index){
                if (orientation == 1)
                    return padding + (index * barWidth);
                else
                    return padding;
            }
        }
        
        var bar_w = function(scale, barWidth, orientation){
            return orientation  == 1 ? barWidth : function(d){return scale(d.value)};
        }
        
        var bar_h = function(scale, barWidth, orientation){
            return orientation == 1 ? function(d){return scale(d.value)} : barWidth;
        }
        
        var set_orientation = function(xtype, ytype){
            orientation = -1;
            
            if (xtype == "numeric"){
                orientation = 0;
            }
            else if (ytype == "numeric"){
                orientation = 1;
            }
            
            return orientation;
        }
        
        var calculate_params = function(options){
                    
            var 
                orientation = set_orientation(options.xtype, options.ytype),
                data        = format_data(options),
                height      = orientation == 1 ? 100 : 300,
                width       = options.width,
                padding     = options.padding,
                scale       = create_scale(data.min, data.max, orientation, width, height, padding),
                barWidth    = bar_width(orientation, width, height, padding, data.values.length),
                barY        = bar_y(scale, barWidth, height, padding, orientation),
                barX        = bar_x(barWidth, padding, orientation),
                w           = bar_w(scale, barWidth, orientation),
                h           = bar_h(scale, barWidth, orientation);
            
            return{
                orientation :orientation,
                data        : data,
                height      : height,
                width       : width,
                padding     : padding,
                scale       : scale,
                barWidth    : barWidth,
                barY        : barY,
                barX        : barX,
                w           : w,
                h           : h,
            }
        }
        
        that.name = function(){
            return name;
        }
        
        that.render = function(options){
         
            $('.chart').empty();
            
            that.visible(false);
             
            params = calculate_params(options);
            
            that.topmargin("margin-top: " + (params.height/2 + 15) + "px");  
            
            if (params.orientation >= 0)
                that.visible(true);
            else
                return;
            
            
            that.chart = d3.select('.chart')
                    .append('svg')
                    .attr({
                        'width': params.width,
                        'height' : params.height ,
                     })
                    .style('border', '1px solid black')
                    .style('padding', '8px');
                    
             that.chart.selectAll('rect.number')
                .data(params.data.values).enter()
                .append('rect')
                .attr({
                    'class':'number',
                    'x': params.barX,
                    'y': params.barY,
                    'width' : params.w,
                    'height' : params.h,
                    'fill' : '#dff',
                    'stroke' : '#444',
                });
        }
        
        
        that.redraw    = function(options){
            
            params = calculate_params(options);
            
            that.topmargin("margin-top: " + (params.height/2 + 15) + "px");  
            
            if (params.orientation >= 0)
                that.visible(true);
            else
                return;
        
            var rect = that.chart.selectAll("rect.number")
                .data(params.data.values, function(d){return d.label});
             
            rect.enter().insert('rect').attr({
                    'class':'number',
                    'x': params.barX,
                    'y': params.barY,
                    'width' : params.w,
                    'height' : params.h,
                    'fill' : '#dff',
                    'stroke' : '#444'});
               
            rect.transition()
                .duration(1000)
                .attr({
                    'x': params.barX,
                    'y': params.barY,
                    
                });
            
            rect.exit()
                .remove();
        }
           
        return that;
 }
 
 
 function ResourceDialogModel(){
    var self = this;
    
    this.currentEntity = ko.observable();
    this.entities = ko.observableArray(["","router", "something else"]);
    
    this.sources = ko.observableArray([]);
    this.currentSource = ko.observable();
    
    this.schema = ko.observableArray([]);
    this.selectedColumns = ko.observableArray([]);

    this.numericTypes = ["float", "int", "long"];    
    this.chartTypes   =  ["bar chart", "table", "scatter plot"];
    
    this.currentType = ko.observable();
    
    this.data         = ko.observableArray([]); 
    this.x            = ko.observable();
    this.y            = ko.observable();
    this.barchart     = ko.observable(barchart());
    
    this.selectAxes   = ko.observable(false);
    this.selectedAxes = ko.observableArray([]);
    this.orderAxis    = ko.observable();
    
    this.orders       = ko.observableArray(["asc", "desc"]);
    
    this.order        = ko.observable("asc");
  
    this.orderby      = ko.observable(1);
    
    this.keys         = ko.observableArray([]);
    this.key          = ko.observable();
    this.latest;
    this.polling      = false;
    
    this.chartVisible = ko.observable(false);
    
    
    this.refreshOptions = ko.observableArray([  "no refresh",
                                                "every 5 seconds",
                                                "every 30 seconds",
                                                "every minute", 
                                                "every 5 minutes",
                                                "hourly", 
                                                "6 hourly", 
                                                "daily"
                                            ]);
    
    this.refreshOption  = ko.observable(this.refreshOptions()[0]);
    
    this.eligibility  = { 
                            "bar chart" : [{"type":"numeric", "count":1}, {"type":"*", "count":1}], 
                            "table"     : [{"type":"*", "count":1}], 
                            "scatter plot" :[{"type":"numeric", "count":2}]
                        }
    
    this.eligibleCharts = ko.observableArray([]);
    
    this.fetchSources= function(){
       
        $.ajax({
                url: "/tables",
                dataType: 'json', 
            
                success: function(data) {
                    console.log(data.tables);
                    self.sources(data.tables);
                    console.log(self.sources());
                }
        });
    }
    
    /*
     * The checked binding only works with strings, so this builds an array of the
     * full objects (rather than just column_name) that were selected.
     */
    this.selectedObjects = ko.computed(function(){
        return ko.utils.arrayMap(self.selectedColumns(), function(id){
            return ko.utils.arrayFirst(self.schema(), function(item){
                return item.column_name == id;
            });
        });
    });
    
    this.selectedObjects.subscribe(function(data){
        console.log(ko.utils.arrayMap(this.selectedObjects(), function(item){
            return item.data_type;
        })
        );
    },this);
    
    this.fetchSchema = function(table){
    
         $.ajax({
                url: "/schema/" + table,
                dataType: 'json', 
            
                success: function(data) {
                    console.log(data.schema);
                    self.schema(data.schema);
                }
        });
    
    }
    
    this.checkEligibility = function(){
        this.eligibleCharts(ko.utils.arrayMap(self.chartTypes, function(item){
            if (self.amEligible(item))
                return item;
        }));
    }
    
    this.amEligible = function(chart){
        types = self.eligibility[chart];
        
        eligible = true;
        
        if (types == undefined){
            return false;
        }
        
        $.each(types, function(i, type){
            //create own deals!
        });
        
        console.log(types); 
        return true;
    }
    
    
    this.schemaType = function(column){
        attr = ko.utils.arrayFirst(self.schema(), function(item){
            return item.column_name == column;    
        });
        
        if (attr){
            if (ko.utils.arrayFirst(self.numericTypes, function(item){return item==attr.data_type}))
                return "numeric"
            return attr.data_type
        }
        return undefined;
    },
    
    this.selectedColumns.subscribe(function(option){
        //console.log(this.selectedColumns());
        this.eligibleCharts([]);
        this.checkEligibility(); 
        this.orderby(this.selectedColumns()[0]);
        
        this.keys(ko.utils.arrayFilter(this.selectedColumns(), function(item){
            if (self.schemaType(item) == "numeric")
                return item;
        }));
        
        if (this.keys().length > 0){   
            this.key(this.selectedColumns()[0]);
        }
        console.log(this.keys());
        
    }, this);
    
    this.currentSource.subscribe(function(option){
        this.fetchSchema(option);
        this.selectedColumns([]);
    },this);
    
    this.currentEntity.subscribe(function(option){
        if (option == "router"){
            console.log("FETCHING SOURCES");
            this.fetchSources();
        }else{
            this.sources([]);
        }
    }, this);
 
    this.currentType.subscribe(function(type){
        this.selectAxes(true);
        this.fetchdata();
    }, this);
    
    
    this.x.subscribe(function(type){
        if (this.data && this.data().length > 0){
            this.selectedAxes([this.x(), this.y()]);
            this.buildchart();
        }
    }, this);
    
    
    this.y.subscribe(function(type){
        if (this.data && this.data().length > 0){
            this.selectedAxes([this.x(), this.y()]);
            this.buildchart();
        }
    }, this);
    
    this.fetchdata = function(callback){
        
        data = {
                    'table'     : this.currentSource(),
                    'columns'   : this.selectedColumns().join(),
                    'limit'     : 20
        };
        
        if (self.latest && self.key()){
            data.key     = self.key();
            data.latest  = self.latest;  
        }
        else if (self.key()){
             data.key     = self.key();
        }
        
        $.ajax({
                url: '/fetch_latest',
                contentType: 'application/x-www-form-urlencoded',
                type: "POST",
                data: data,
                dataType: 'json',
                
                success: function(data){
                    self.data.shift();
                    self.data(self.data().concat(data)); 
                   
                    if (callback){
                        callback();
                    }
                },
                error: function(XMLHttpRequest, textStatus, errorThrown){
                    if (error_callback){
                         error_callback(XMLHttpRequest, textStatus, errorThrown);
                    }       
                }
        });
    },
    
    this.toggleOrder = function(){
        if (this.order() == "asc")
            this.order("desc");
        else
            this.order("asc");
    }

    this.buildchart = function(){

        self.barchart().render({
                                data:self.data(),
                                x: self.x(),
                                y: self.y(),
                                xtype: self.schemaType(self.x()),
                                ytype: self.schemaType(self.y()),
                                width: 280,
                                padding: 8,
                            });  
    }
    
    
    this.redraw = function(){
      
        self.barchart().redraw({
                                data:self.data(),
                                x: self.x(),
                                y: self.y(),
                                xtype: self.schemaType(self.x()),
                                ytype: self.schemaType(self.y()),
                                width: 280,
                                padding: 8,
                            });  
    }
    
    this.sortx = function(){
        this.orderby(this.x());
        this.fetchdata(self.buildchart);
        this.toggleOrder();
    },
    
    this.sorty = function(){
        this.orderby(this.y());
        this.fetchdata(self.buildchart);
        this.toggleOrder();
    },
    
    this.recalculate_latest = function(){
        self.latest = 0;
        if (self.key()){
            ko.utils.arrayForEach(self.data(), function(item) {
                self.latest = Math.max(self.latest, item[self.key()]);
            });
         }
         console.log("recalculated latest as " + self.latest);
    },
    
    
    this.polldata = function(frequency){
        self.polling = true;
        
        setTimeout(function(){
            self.fetchdata(self.redraw);
            self.polldata(5000);
        },frequency);
    }
        
    
    this.refreshOption.subscribe(function(newValue){
        if (newValue != "no refresh"){
            if (!self.polling){
                self.polldata(500);
            }
        }
    },this);
    
    this.key.subscribe(function(newValue){
        this.recalculate_latest();
    },this);
    
    this.barchart().visible.subscribe(function(newValue){
        this.chartVisible(newValue);
    },this);
    
    this.data.subscribe(function(newValue){
        //recalculate the 'latest' value we have for our data
         this.recalculate_latest();
        
    },this);
 }
 
 function ResourceModel(){
        
        var self = this;
        
        var options = {};
        
    
        this.selectedResource = ko.observable("");
        this.dialogModel = new ResourceDialogModel();
       
       
        
        this.resources = ko.observableArray([]);
        
        this.event = ko.observable().subscribeTo("myevents", true);
        
        this.wizard =  $("#some-wizard").wizard(options);
        
        this.resourceDialog = function(){
           self.wizard.show();
           ko.applyBindings(self.dialogModel, $(".wizard-modal")[0]);
        }
        
        this.amActive = function(resourcename){
            return resourcename == self.selectedResource().resource_name();
        }
        
        this.loadResources = function(data){
            
            $.each(data, function(i, item){
                resource = ko.mapping.fromJS(item);
                resource.install_url = ko.computed(function(){  
                    return "install?resource_name=" + resource.resource_name(); 
                });
                console.log("adding resource..." + resource.resource_name());
                
                self.resources.push(resource);
            });
           
            self.selectedResource(self.resources()[0]);
            console.log("resources are..");
            console.log(self.resources());
        };
        
       
        
        
        
        this.selectedResource.subscribe(function(resource){
            console.log(resource.resource_name());
            
            $.ajax({
                    url: "/static/dynamic_views/" + resource.resource_name() + ".html",
                    dataType: 'html', 
                
                    success: function(data) {
                        $(".myview").empty();
                        $(".myview").append(data);
                    }
            });
        },this);
        
        /*this.requestText = ko.computed(function(){
            if (self.selectedUrl())
                return self.selectedUrl().requests  + " requests";
            return "";
        });*/
    } 
</script>

<script>
    function ExecutionModel(){
       
        
        var self = this;
         
        this.executions = ko.observableArray([]);
        
        this.tsToString = function(ts){
            function pad(n) { return n < 10 ? '0' + n : n }
             
            a = new Date(ts);
            
            months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            
            year = a.getFullYear();
            month = months[a.getMonth()];
            day = a.getDate();
        
            hour = pad(a.getUTCHours());
            min = pad(a.getUTCMinutes());
            sec = pad(a.getUTCSeconds());
            return  day+' '+month+' '+year + "," + hour + ":" + min + ":" + sec;
        }
        
        //filter out all execution events from the pool of all events.
        this.loadData = function(data){
            $.each(data, function(i, execution){
                execution.result = $.parseJSON(execution.result);
                execution.executed = self.tsToString( execution.executed * 1000);
                self.executions.push(execution);
            });    
        };
        
        ko.postbox.subscribe("myevents", function(newValue) {
            if (newValue.type == "execution"){
                execution = $.parseJSON(newValue.data);
                //turn the result to an object too..
                execution.result = $.parseJSON(execution.result);
                execution.executed = self.tsToString( execution.executed * 1000);
                this.executions.push(execution);
            }
        }, this);
        
    }
</script> 

<script>

	//PREFSTORE = "http://hwresource.block49.net:9000/" 
	 
	$( document ).ready( function() {
		$( 'a.menu_button' ).click( function() {
			self.parent.location=  $( this ).attr('id');
		});
		var nm = new NotificationModel();
		ko.applyBindings(nm,$(".navbar-inner")[0]);  
        nm.startpolling();
	});
</script>

</head>

<body>
<div class="navbar">
    <div class="navbar-inner">
        <a class="brand" href="#">My dataware resources</a>
        <ul class="nav">
            <li><a href="#" class="menu_button" id="home">home</a></li>
            
            %if user:
            <li><a href="#" class="menu_button" id="view_executions">executions</a></li>
            <li><a href="#" class="menu_button" id="logout">logout</a></li>
            %else:
            <li><a href="#" class="menu_button" id="login">login/register</a></li>
            %end
        </ul>
        <ul class="nav pull-right">                            
            <li class="dropdown">
                <a class="dropdown-toggle" id="dLabel" role="button" data-toggle="dropdown" data-target="#" href="#"> 
                <span class="badge badge-success" data-bind="text:events().length"></span>
                    <b class="caret"></b>
                </a>
                <ul class="dropdown-menu" role="menu" aria-labelledby="dLabel" data-bind="{foreach: events}">
                    <li> 
                        <a href="#" data-bind="click:function(){$parent.read($data);}"> 
                        <span data-bind="text:message"></span> 
                        </a>
                    </li>
                </ul>
            </li>                  
        </ul>
    </div>
</div>

<div class="container">
    <div class="row">
        <div class="span4 offset8">
            <div class='notifications top-right'></div>
        </div>
    </div>
</div>