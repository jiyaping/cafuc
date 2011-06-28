require "rubygems"
require "sinatra"
require "active_record"

############ conifg ###############

db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')

ActiveRecord::Base.establish_connection(
  :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
  :host     => db.host,
  :username => db.user,
  :password => db.password,
  :database => db.path[1..-1],
  :encoding => 'utf8'
)

=begin
ActiveRecord::Base.establish_connection(
	:adapter => "mysql",
	:host => "localhost",
	:username => "root",
	:password => "root",
	:database => "sinatra"
)
=end

ActiveRecord::Base.establish_connection(
	:adapter=>"sqlite3",
	:database=>"main.sqlite3"
)

enable :sessions

############# models ###############

class Student < ActiveRecord::Base
	has_one :profile
end

class Profile < ActiveRecord::Base
	belongs_to :student
end

class Admin < ActiveRecord::Base
end

class AddAdmin < ActiveRecord::Migration
	def self.up
		create_table :admins do |t|
			t.string :adminname
			t.string :adminpwd
		end
	end

	def self.down
		drop_table :admins
	end
end

if not Admin.table_exists?
	AddAdmin.up
end

class AddProfile < ActiveRecord::Migration
	def self.up
		create_table :profiles do |t|
			t.integer :student_id,:unique=>true
			t.string  :name
			t.string  :jiguan
			t.string  :xingbie
			t.string  :minzu
			t.string  :techang
			t.string  :identify
			t.date  :birthday
			t.string  :address
			t.date  :entry_time
			t.boolean :if_locked,:default=>false
		end
	end

	def self.down
		drop_table :profiles
	end
end

if not Profile.table_exists?
	AddProfile.up
end

class AddStudent < ActiveRecord::Migration
	def self.up
		create_table :students do |t|
			t.string :number
			t.string :password
			t.string :email
		end
	end

	def self.down
		drop_table :students
	end
end

if not Student.table_exists?
	AddStudent.up
end


############# routes ###############
helpers do
	def time_to_zh(date)
		if date.respond_to? "strftime"
			date.strftime("%Y-%m-%d")
		else
			"xxxx-xx-xx"
		end
	end

	def get_page_data(product,per_page,current_page)
		max_page = (product.size/per_page.to_f).ceil
		if(current_page<=max_page)
			product[per_page*(current_page-1)...per_page*current_page]
		else
			session["error"] = "There is no page"
			redirect back
		end
	end
end

get "/" do
	erb :index,:layout=>:user_layout
end

get "/jquery.js" do
	"js/jquery.js"
end

get "/jeditable.js" do
	"js/jeditable.js"
end


get "/student/login" do
	session[:number] = nil
	number = params[:number]
	password = params[:password]
	stu = Student.where("number=? and password=?",number,password)
	if stu.length!=0
		session[:number] = stu[0].number
		status 200
		{"number"=>number}.to_json
	else
		status 400
		{"error"=>"number or password is not correct"}.to_json
	end
end

get "/logout" do
	session[:adminname]=nil
	session[:number] = nil
	redirect to("/")
end

get "/validate/number" do
	number = params[:number]
	stu = Student.where("number=?",number)
	if stu.length!=0
		status 400
	else
		status 200
	end
end

post "/student/register" do
	number = params[:number]
	password = params[:password]
	email = params[:email]
	stu = Student.new
	stu.number = number
	stu.password = password
	stu.email = email
	if stu.save
		session[:number] = stu.number
		status 200
		{"info"=>"register success"}.to_json
	else
		status 400
		{"info"=>"failed register"}.to_json
	end
	#{"number"=>number,"password"=>password,"email"=>email}.to_json
end

get "/student/profile" do
	@number = session[:number]
	erb :profile,:layout=>:user_layout
end

post "/student/profile" do
	profile = Profile.new
	profile.student_id = session[:number]
	profile.name = params[:name]
	profile.jiguan =  params[:jiguan]
	profile.xingbie =  params[:sex]
	profile.minzu =  params[:minzu]
	profile.techang =  params[:techang]
	profile.identify =  params[:identify]
	profile.birthday =  params[:birthday]
	profile.address =  params[:address]
	profile.entry_time =  params[:entry_time]

	if profile.save
		redirect to("/#{session[:number]}")
	else
		redirect back
	end
end

get "/:number" do
	@number = params[:number]
	@profile = Profile.where("student_id=?",params[:number])[0]
	if @profile.nil?
		@profile = Profile.new
	end
	#"#{@profile[0].name}"
	erb :show,:layout=>:user_layout
end


post "/student/update/name/:stu_id" do
	@profile = Profile.where("student_id=?",params[:stu_id])[0]
	@profile.name = params[:value]
	if @profile.save
		@profile.name
	else
		status 500
	end
end

post "/student/update/jiguan/:stu_id" do
	@profile = Profile.where("student_id=?",params[:stu_id])[0]
	@profile.jiguan = params[:value]
	if @profile.save
		@profile.jiguan
	else
		status 500
	end
end

post "/student/update/xingbie/:stu_id" do
	@profile = Profile.where("student_id=?",params[:stu_id])[0]
	@profile.xingbie = params[:value]
	if @profile.save
		@profile.xingbie
	else
		status 500
	end
end

post "/student/update/minzu/:stu_id" do
	@profile = Profile.where("student_id=?",params[:stu_id])[0]
	@profile.minzu = params[:value]
	if @profile.save
		@profile.minzu
	else
		status 500
	end
end

post "/student/update/birthday/:stu_id" do
	@profile = Profile.where("student_id=?",params[:stu_id])[0]
	@profile.birthday = params[:value]
	if @profile.save
		time_to_zh(@profile.birthday)
	else
		status 500
	end
end

post "/student/update/entry_time/:stu_id" do
	@profile = Profile.where("student_id=?",params[:stu_id])[0]
	@profile.entry_time = params[:value]
	if @profile.save
		time_to_zh(@profile.entry_time)
	else
		status 500
	end
end

post "/student/update/techang/:stu_id" do
	@profile = Profile.where("student_id=?",params[:stu_id])[0]
	@profile.techang = params[:value]
	if @profile.save
		@profile.techang
	else
		status 500
	end
end

post "/student/update/address/:stu_id" do
	@profile = Profile.where("student_id=?",params[:stu_id])[0]
	@profile.address = params[:value]
	if @profile.save
		@profile.address
	else
		status 500
	end
end

get "/admin/login" do
	erb :admin_login,:layout=>:user_layout
end

post "/admin/login" do
	admin_name = params[:adminname]
	admin_pwd = params[:adminpwd]

	@admin = Admin.where("adminname=? and adminpwd=?",admin_name,admin_pwd)[0]
	if @admin
		session[:adminname] = @admin.adminname
		redirect to("/admin/list")
	else
		redirect to("/admin/login")
	end
end

get "/admin/list" do
	students = Profile.find(:all)
	#"#{@students.size}"
	@students = get_page_data(students,10.0,1)
	@max_page = (students.size/10.0).ceil
	erb :list,:layout=>:user_layout
end

get "/admin/list/:number" do
	students = Profile.find(:all)
	@students = get_page_data(students,10.0,params[:number].to_i)
	@max_page = (students.size/10.0).ceil
	#"#{(students.size/10.to_f).ceil}"
	erb :list,:layout=>:user_layout
end

get "/admin/search" do
	stu_id = params[:student_id]
	stu_name = params[:name]
	@students
	if stu_id!=""
		if stu_name!=""
			@students = Profile.where("student_id=? and name=?",stu_id,stu_name)
		else
			@students = Profile.where("student_id=?",stu_id)
		end
	else
		if stu_name!=""
			@students = Profile.where("name=?",stu_name)
		else
			@students = []
		end
	end
	@max_page=0
	erb :list,:layout=>:user_layout
end

get "/admin/delete" do
	stu_id = params[:stu_id]
	if Profile.delete(Profile.where("student_id=?",stu_id)[0].id)==1
		status 200
		"success"
	else
		status 500
	end
end

############# views ###############


__END__
@@ layout
<<html>
<head>
	<title>test layout 1</title>
</head>
<body>
	<h1>layout 1</h1>
	<div><%=yield%></div>
</body>
</html>

@@ list
<style type="text/css">
#result{
	margin:0px 0px 0px 20px;
	padding: 20px 0 300px 20px;
}

#search{
	margin: 10px 10px 20px 50px;
    padding: 20px;
}

#search input{
	height: 30px;
    width: 200px;
}

#search label{
	font-size: 15px;
    font-weight: bold;
    color:lightblue;
}

#result-header{
	font-size: 18px;
    font-weight: bold;
}

#result-header span{
	margin: 30px;
    padding: 10px;
}

#list{
	margin: 30px;
}

#list h1{
	color: lightBlue;
    letter-spacing: 3px;
    margin: 20px 20px 10px 35px;
}

table{
	width: 700px;
}

.thead{
	color: black;
    font-size: 15px;
    font-weight: bold;
}

tr{
	height: 30px;
}

td{
	color: black;
    font-size: 15px;
}
#pages{
	font-size: 15px;
    margin: 30px 0 10px;
}
</style>

<script type="text/javascript">
	$(function(){
		$(".delete-item").click(function(){
			var stu = $(this).attr("id");
			$("#result-item-"+stu).ajaxStart(function(){
				$(this).empty().append("<span>please waiting ....</span>");
			});
			$.ajax({
				type:"get",
				url:"/admin/delete",
				data:{stu_id:stu},
				dataType:"text",
				success:function(data){
					if(data=="success"){
						$("#result-item-"+stu).remove();
						//alert("ok");
					}
				}
			});
		});
	});
</script>

<div id="search">
	<form action="/admin/search" method="get">
	<label>Student ID</label>
	<input class="search" type="text" id="student_id" name="student_id"/>
	<label>Student Name</label>
	<input class="search" type="text" id="name" name="name"/>
	<input type="submit" value="Go Search" id="SearchButton"/>
	</form>
</div>
<div id="list">
<h1>Student List</h1>
<div id="result">
	<table>
	<tr>
	<td><span class="thead">Student Id</span></td>
	<td><span class="thead">Name</span></td>
	<td><span class="thead">Xingbie</span></td>
	</tr>
	<%@students.each do |student| %>
		<tr class="result-item" id="result-item-<%=student.student_id%>">
			<td><%=student.student_id%></td>
			<td><%=student.name%></td>
			<td><%=student.xingbie%></td>
			<%if session[:adminname]%>
				<td><a class="show-item" href="/<%=student.student_id%>">showAndupdate</a></td>
				<td><a class="delete-item" id="<%=student.student_id%>">delete</a>
				</td>
			<%end%>
		</tr>
	<% end %>
	</table>
		<%if @max_page>1%>
			<div id="pages">
			<span>Pages >> </span>
			<%@max_page.times do |page_id|%>
				<span><a href="/admin/list/<%=page_id+1%>"><%=page_id+1%></a></span>
			<% end %>
			</div>
		<% end %>
</div>
</div>
@@admin_login
<style type="text/css">
	#admin_login{
		margin:0px 0px 0px 20px;
		padding: 20px 0 300px 20px;
	}

	input{
	color:black;
	border-bottom: 1px solid #FFFFDD;
    font-size: 20px;
    height: 30px;
    margin-bottom: 10px;
    width: 300px;
	}

</style>

<div id="admin_login">
<h1>Admin</h1>
<form action="/admin/login" method="post">
	<label>Admin Name</label><br />
	<input type="text" name="adminname"/><br />
	<label>Admin Password</label><br />
	<input type="password" name="adminpwd" /><br />
	<input type="submit" value="login"/>
</form>
</div>



@@ show
<style type="text/css">
	h1{
		font-size:25px;
		margin-bottom:20px;
		color:grey;
	}
	#show_user{
		margin:0px 0px 0px 20px;
		padding: 20px 0 200px 20px;
	}

	#show_user div span{
	border-bottom: 1px solid #FFDDDD;
	color: lightBlue;
    display: block;
    font-size: 18px;
    margin: 5px;
    text-align: right;
    width: 200px;

	}

	.attr{
		margin-bottom:5px;
	}

	#show_user div div{
	font-size: 20px;
    letter-spacing: 1.5px;
    margin-left: 220px;
    margin-right: 300px;
    color:grey;
	}
</style>

<%if @profile.student_id.to_s== session[:number] || session[:adminname]!=nil%>

<script type="text/javascript">
$(function(){
	$("#name").editable(buildLink("name"),{
		indicator : '<img src="image/ajax-loader.gif">',
        tooltip   : 'Click to edit...'
	});
	$("#jiguan").editable(buildLink("jiguan"),{
		indicator : '<img src="image/ajax-loader.gif">',
        tooltip   : 'Click to edit...'
	});
	$("#xingbie").editable(buildLink("xingbie"),{
		indicator : '<img src="image/ajax-loader.gif">',
        tooltip   : 'Click to edit...'
	});
	$("#minzu").editable(buildLink("minzu"),{
		indicator : '<img src="image/ajax-loader.gif">',
        tooltip   : 'Click to edit...'
	});
	$("#birthday").editable(buildLink("birthday"),{
		indicator : '<img src="image/ajax-loader.gif">',
        tooltip   : 'Click to edit...'
	});
	$("#address").editable(buildLink("address"),{
		indicator : '<img src="image/ajax-loader.gif">',
        tooltip   : 'Click to edit...'
	});
	$("#entry_time").editable(buildLink("entry_time"),{
		indicator : '<img src="image/ajax-loader.gif">',
        tooltip   : 'Click to edit...'
	});
	$("#techang").editable(buildLink("techang"),{
		indicator : '<img src="image/ajax-loader.gif">',
        tooltip   : 'Click to edit...',
        type:"textarea",
        rows:10,
        cols:35,
        submit:"submit",
        cancel:"cancel"
	});
});

function buildLink(str){
	var stu_id = $("#student_id").text();
	return "/student/update/"+str+"/"+stu_id;
}
</script>

<% end %>

<div id="show_user">
	<h1>Student Profile</h1>
	<div class="attr"><span>Student Number</span><div id="student_id"><%=session[:number]||@number%></div></div>
	<div class="attr"><span>Student Name</span><div id="name"><%= @profile.name%></div></div>
	<div class="attr"><span>JiGuan</span><div id="jiguan"><%= @profile.jiguan%></div></div>
	<div class="attr"><span>XingBie</span><div id="xingbie"><%= @profile.xingbie%></div></div>
	<div class="attr"><span>MinZu</span><div id="minzu"><%= @profile.minzu%></div></div>
	<div class="attr"><span>Birthday</span><div id="birthday"><%= time_to_zh(@profile.birthday)%></div></div>
	<div class="attr"><span>Address</span><div id="address"><%= @profile.address%></div></div>
	<div class="attr"><span>Entry time</span><div id="entry_time"><%= time_to_zh(@profile.entry_time)%></div></div>
	<div class="attr"><span>TeChang</span><div id="techang"><%= @profile.techang%></div></div>
</div>

@@profile

<style>
#profile{
	margin:0px 0px 0px 20px;
	padding: 20px 0 300px 20px;
}
fieldset {
	border:1px dashed #CCC;
	padding:10px;
	margin-right: 30px;
}
legend {
	background: none repeat scroll 0 0 grey;
    border: 0 solid lightBlue;
    color: #FFFFFF;
    font-family: Arial,Helvetica,sans-serif;
    font-size: 20px;
    font-weight: bold;
    letter-spacing: -1px;
    line-height: 1.1;
    padding: 2px 6px;
}

form{
	margin:20px 0px 0px 40px;
}

label{
	color: grey;
    font-family: Arial,Helvetica,sans-serif;
    font-size: 20px;
    font-weight: normal;
    letter-spacing: 2px;
    line-height: 1.5;
}
input{
	color:black;
	border-bottom: 1px solid #FFFFDD;
    font-size: 20px;
    height: 30px;
    margin-bottom: 10px;
    width: 300px;
}

textarea{
	border-bottom: 1px solid grey;
	height: 150px;
    margin-bottom: 10px;
    width: 400px;
}

#sub-fieldset{
	width: 280px;
}
#sub-fieldset legend{
	background-color: #DDDDDD;
    font-size: 18px;
}

#sub-fieldset input{
	margin-left:30px;
	margin-right:5px;
}
</style>

<script type="text/javascript">

</script>

<div id="profile">
	<fieldset>
		<legend>Profile</legend>
			<form action="/student/profile" method="post">
				<label>Number</label><br />
				<input type="text" id="number" disabled="disabled" name="number" value="<%=@number%>"/><br />
				<label>Name</label><br />
				<input type="text" id="name" name="name"/><br />
				<label>Jiguan</label><br />
				<input type="text" id="jiguan" name="jiguan"/><br />
				<label>minzu</label><br />
				<input type="text" id="minzu" name="minzu"/><br />
				<label>Address</label><br />
				<input type="text" id="address" name="address"/><br />
				<fieldset id="sub-fieldset"><legend>Xingbie</legend>
				<input type="radio" name="sex" value="male"/>Male
				<input type="radio" name="sex" value="female"/>Female<br /></fieldset>
				<label>Identify</label><br />
				<input type="text" name="identify"/><br />
				<label>Birthday</label><br />
				<input type="text" name="birthday"/><br />
				<label>Entry Time</label><br />
				<input type="text" name="entry_time" /><br />
				<label>Techang</label><br />
				<textarea name="techang"></textarea><br />
				<input type="submit" id="push_profile" value="profile it"/>
			</form>
	</fieldset>
</div>

@@index
<style type="text/css">
	#login_or_register{
		margin:0px 0px 0px 20px;
		padding: 20px 0 300px 20px;
	}
	label{
		font-size:20px;
		font-weight:150%;
		width:50px;
		font-align:right;
	}
	input{
		margin:3px;
	}
	#login{

	}
	.register,.login{
		background-color: #FFFFDD;
    	padding: 20px;
    	width: 400px;
	}
	.sub-separator{
		border-bottom:1px solid grey;
		margin: 10px 0;
    	width: 80%;
	}
	#change_login_register{
		margin-left:10px;
	}
	.error-info{
		color:red;
		font-size:12px;
	}
	#pro_link{
		font-size: 30px;
    	margin-left: 200px;
    	padding-top: 200px;
	}
</style>

<script>
$(function(){
	$(".login").hide();
	$("#change_register_login").click(function(){
		$("#student-info").empty();
		$(".register").hide();
		$(".login").show("slow");
	});
	$("#change_login_register").click(function(){
		$("#student-info").empty();
		$(".login").hide();
		$(".register").show("slow");
	});
	$("#login").click(function(){
		var nb = $("#login_number").val();
		var pwd = $("#login_password").val();
		$("#login").ajaxStart(function(){
			$("#login_load").show();
		});
		$.ajax({
			type:"get",
			url:"/student/login",
			data:{number:nb,password:pwd},
			dataType:"json",
			success:function(data,textStatus){
				var info = "<span>welcome <a  style='color:white;font-size:13px;font-weight:bold;' href='/"+data.number+"'>"+data.number+
						"</a>[<a href='/logout'>logout</a>]</span>";
				if(data!=""){
					$("#student-info").append(info);
				}
			},
			error:function(data){
				if(data!=""){
					alert(typeof data);
				}
			}
		});
		$("#login").ajaxComplete(function(){
			$("#login_load").hide();
		});
	});

	$("#number").focusin(function(){
		$("#number_error").remove();
		});
	$("#number").change(function(){
		var number = $(this).val();
		if(number==""){
			$(this).after("<span class='error-info' id='number_error'>number could not be null</span>");
		}
		$(this).ajaxStart(function(){
			$("#number_load").show();
		});
		$.ajax({
			type:"get",
			url:"/validate/number",
			data:"number="+number,
			error:function(){
				$("#number").after("<span class='error-info' id='number_error'>number is exists!</span>");
			}
		});
		$(this).ajaxComplete(function(){
			$("#number_load").hide();
		});
	});

	$("#password_confirm").focusin(function(){
		$("#password_error").remove();
	});

	$("#password_confirm").change(function(){
		var pwd = $("#password").val();
		var com_pwd = $("#password_confirm").val();
		if(pwd!=com_pwd){
			$(this).after("<span class='error-info' id='password_error'>two password is not equal</span>");
		}
	});

	$("#signin").click(function(){
		var nb = $("#number").val();
		var pwd = $("#password").val();
		var email = $("#email").val();
		$(this).ajaxStart(function(){
			$("#number_load").remove();
			$("#register_load").show();
		});
		$.ajax({
			type:"post",
			url:"/student/register",
			data:{number:nb,password:pwd,email:email},
			dataType:"text",
			success:function(data){
				$(".register").remove();
				$(".login").remove();
				var profile_link = "<div id='pro_link'><a href='"+"/student/profile"+
				"'>Contiune to Complete My Profile</a></div>";
				$("#login_or_register").append(profile_link);
			},
			error:function(data){
				alert(data);
			}
		});
		$(this).ajaxComplete(function(){
			$("#register_load").hide();
		});
	});
});
</script>

<div id="login_or_register">
  <div class="register">
    <h1>Sign In</h1>
    <div class="sub-separator"></div>
  	<label>Number</label><br />
	<input type="text" id="number"/><img id="number_load" src="image/ajax-loader.gif" style="display:none"/><br />
	<label>Password</label><br />
	<input type="password" id="password"/><br />
	<label>Password again</label><br />
	<input type="password" id="password_confirm"/><br />
	<label>Email</label><br />
	<input type="text" id="email"/><br />
	<input type="submit" id="signin" value="SignIn"/>
	<img id="register_load" src="image/ajax-loader.gif" style="display:none"/>
	<a href="#" id="change_register_login">i have an account aready!</a>
  </div>
  <div class="login">
  	<h1>Login</h1>
  	<div class="sub-separator"></div>
  	<label>Number</label><br />
  	<input type="text" id="login_number"/><br />
  	<label>password</label><br />
  	<input type="password" id="login_password"/><br />
  	<input type="submit" id="login" value="login" />
  	<img id="login_load" src="image/ajax-loader.gif" style="display:none"/>
  	<a href="#" id="change_login_register">i don't have a account!</a>
  </div>
</div>

@@user_layout
<html>
	<head>
		<title>user index</title>
		<script type="text/javascript" src="/js/jquery.js"></script>
		<script type="text/javascript" src="/js/jeditable.js"></script>
		<style type="text/css">
			*{
    			font-weight: normal;
    			list-style: none outside none;
    			margin: 0;
    			outline: medium none;
    			padding: 0;
    			text-decoration: none;
    			vertical-align: baseline;
			}
			a{
				 color: #336699;
				 cursor: pointer;
			}

			a:hover{
				background-color:lightblue;
			}

			#container{
				background: url("/image/bg.png") repeat-x scroll 0 0 #105C9A;
				color: black;
  				font: normal 12px verdana, arial, helvetica, sans-serif;
  				line-height: 1.5;
  				padding: 0px;
  				margin: 0px;
			}

			.separator{
				border: 1px solid white;
    			margin: 10px 0 10px 125px;
    			text-align: center;
    			width: 76%;
			}

			#header{
    			color: white;
    			font-size: 30px;
    			margin-left: 125px;
    			padding: 10px;
    			width: 960px;
			}

			#header div{
				font-weight:bold;
			}

			#student-info{
				font-size:13px;
				text-align:right;
				height: 20px;
			}

			#content{
				background-color: white;
    			margin-left: 130px;
    			width: 960px;
			}

			#footer{
				padding: 20px 0 30px 0;
			}

			#footer p{
				color:white;
				text-align:center;
			}
			#footer p a {color:grey;}
		</style>
	</head>

	<body>
		<div id="container">
			<div id="header">
				<div id="main-title">Cafuc Student Management System</div>
				<div id="student-info">
				<%if session[:number]%>
					<span>welcome <a style='color:white;font-size:13px;font-weight:bold;' href="/<%=session[:number]%>"><%=session[:number]%></a>[<a href="/logout">logout</a>]</span>
				<%end%>
				</div>
			</div>
			<div class="separator"></div>
			<div id="content"><%=yield%></div>
			<div class="separator"></div>
			<div id="footer">
				<p>&copy;Developed by <a href="mailto:jiyaping0802@gmail.com">jiyaping</a>
				       <span> all rights reserved</span></p>
			</div>
		</div>
	</body>
</html>

