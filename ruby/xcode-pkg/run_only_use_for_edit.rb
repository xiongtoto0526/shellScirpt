require 'xcodeproj'
require  File.join("./",'./utils.rb')
require 'pathname'
require 'yaml'



p ""
p ""
p "======== loading config ========"

config = YAML.load(File.open(Pathname.new("./config.yaml")))
run_config = YAML.load(File.open(Pathname.new("./run.yaml")))

commit_hash = run_config["commit_hash"];


# 命令行当前支持一个参数:
# 1. project_file_path，工程文件的绝对路径文件名（文件名）。
# 使用举例：
# ruby run.rb /dir1/dir2/ios-bi-demo.xcodeproj  

# 注意: 
# 1.  若在命令行参入project_file_path，同时在config.yaml中传入定义了project_file_path，则优先使用命令行传入的参数值。
# 2.  targetName只能从config.yaml中配置。     

basic_target_name= config["targetName"].to_s+".xcodeproj"
project_file_path=""

p ARGV[0].to_s+"../../../"+basic_target_name
p File.exist?(ARGV[0].to_s+"../../../"+basic_target_name)

# 1.通过读取命令行参数，设置project_file_path
if ARGV.length>0 && File.exist?(ARGV[0].to_s) && (ARGV[0].to_s.split('/')[-1].to_s.include? ".xcodeproj")
    p "project file found, will use ARGV[0]"
    project_file_path = ARGV[0].to_s
    p "project_file_path is :"+project_file_path
# 2.该分支仅用于适配run.command，以便无需配置project_file_path, 直接在当前目录打包。 
elsif ARGV.length>0 && File.exist?(ARGV[0].to_s+"../../../"+basic_target_name)
  p "project file found, will use ARGV[0]+basic_target_name"
  project_file_path = ARGV[0].to_s+"../../../"+basic_target_name
  p "project_file_path is :"+project_file_path
# 3.只有当根据命令行参数，无法找到有效的工程文件时，才会通过读取config.yaml，设置project_file_path
else
  p "No valid argument param found , will use all config in config.yaml ..."
  project_file_path = config["project_file_path"].to_s
  p "project_file_path is :"+project_file_path
end

# p "project_file_path is :"+project_file_path

xgsdk_sdkAppid=config["xgsdk_sdkAppid"].to_s
xgsdk_sdkAppkey=config["xgsdk_sdkAppkey"].to_s
  
p "sdk_app_id is: "+xgsdk_sdkAppid
p "sdk_app_key is: "+xgsdk_sdkAppkey
# p puts Pathname.new(File.dirname(__FILE__)).realpath

# the following params is provided by user...
xgsdk_appid=config["appId"].to_s
xgsdk_appkey=config["appKey"].to_s
xgsdk_channelid=config["xgsdk_channelid"].to_s
bundle_id = config["bundle_id"].to_s
url_sheme_name = bundle_id+".alipay"
XgRechargeUrl = config["XgRechargeUrl"].to_s
XgAuthUrl = config["XgAuthUrl"].to_s
XgDataUrl = config["XgDataUrl"].to_s

# the following params is generated by the params listed above...
p "======== initializing ========"
if basic_target_name==nil
  p "no availabel target found,will use default target name from xcodeProj"
  basic_target_name = project_file_path.split('/')[-1]
else
  p "target name is:"+basic_target_name
end

sdk_target_name = "xg_"+xgsdk_channelid
sdk_group_name= "xg_"+xgsdk_channelid
sdk_product_name= sdk_target_name+".app"
sdk_plist_name = xgsdk_channelid+"_info.plist"
project_path= project_file_path.split('/').slice(0..-2).join('/')
#res_path = project_path+"/xg_package/channels/"+xgsdk_channelid+"/res"

pathname = Pathname.new(File.dirname(__FILE__)).realpath+""
res_path = pathname.to_s.split(":")[0]+"/res"

# relative path
relative_res_path = "$(SRCROOT)"+"/xg_package"+res_path.split("xg_package")[1];
relative_info_path = "$(SRCROOT)/xg_InfoPlist";

p "relative_res_path is: "+relative_res_path
p "relative_info_path is: "+relative_info_path


p "res_path is..."
p res_path
xcode_system_path = "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
system_lib_path = xcode_system_path +"/usr/lib"
system_framworks_path = xcode_system_path + "/System/Library/Frameworks"
info_path = project_path+"/xg_InfoPlist"
tag_file = info_path+"/tag_info.plist"
temp_file = info_path+"/temp_info.plist"
dest_file = info_path +"/"+xgsdk_channelid+"_info.plist"
relative_dest_file = relative_info_path+"/"+xgsdk_channelid+"_info.plist"


# add xgsdk_info_file
xgsdk_info_file_name = "xgsdk_"+xgsdk_channelid+"_info.plist"
xgsdk_info_file = res_path +"/bundle/"+xgsdk_info_file_name

#-------------------------------------------------------------------------
p ""
p "1: ======== clear the old target and group ========"
proj = Xcodeproj::Project.open(project_file_path)
# find basic target
basicTarget=Utils::XGSDK.findBasicTarget(proj,basic_target_name)

if basicTarget==nil
p "======> target name config error !!! will return... "
return
end


# delete old target
Utils::XGSDK.clearOldProduct(proj,sdk_product_name)

p "create: target"
product_group=Utils::XGSDK.getProductGroup(proj)


p "tttt"
p product_group

p "create: group"
plugin_group = Utils::XGSDK.creatNewGroup(proj,"xg_plugin")
sdk_group = Utils::XGSDK.creatNewGroup(plugin_group,sdk_group_name)
sdk_group.clear
library_group=sdk_group.new_group("library")
framework_group=sdk_group.new_group("framework")
srouce_group=sdk_group.new_group("src")
bundle_group=sdk_group.new_group("bundle")

p "tttt--library_group"
p library_group

#-------------------------------------------------------------------------
# update build setting
p ""
p "2: ======== update build setting ========"
p "update: build setting"
p basicTarget.build_settings("Debug")

Utils::XGSDK.addOtherLinkFlag(basicTarget,run_config["otherLinkFlag"])
# Utils::XGSDK.addCodeSignPath(basicTarget,"$(SDKROOT)/ResourceRules.plist")
# Utils::XGSDK.addRunSearchPath(basicTarget,"$(inherited) @executable_path/Frameworks")
if run_config["CxxLibraryConfig"]!=nil
p "will modify c++ lib ..."
Utils::XGSDK.addCPlusLibConfig(basicTarget,run_config["CxxLibraryConfig"])  
end


if run_config["isDisableBitCode"]
p "will disable bitcode ..."
Utils::XGSDK.disableBitCodeFlag(basicTarget)
end


p "update: searchPath..;"
Utils::XGSDK.addFrameSearchPath(basicTarget,[relative_res_path+"/frame"])
Utils::XGSDK.addLibSearchPath(basicTarget,[relative_res_path+"/lib"])
Utils::XGSDK.addHeaderSearchPath(basicTarget,[relative_res_path+"/src"])
p "----"
# p newTarget.build_settings("Release")

p "update: plist..."
plist_path_name = basicTarget.build_settings("Debug")["INFOPLIST_FILE"]
proj_file = project_path+"/"+plist_path_name

if (!File.directory?(info_path))
  p "will create dir.."
  Dir::mkdir(info_path)
end



# read plist file
hashPlist = Xcodeproj::PlistHelper.read(proj_file)

# fix unity version screenLaunch bug
# if hashPlist["UILaunchImages"]!=nil
# hashPlist["UILaunchImages"]=[]
# end
# # fix screenLaunch bug for iphone4s ios8.3
# if hashPlist["UILaunchStoryboardName~iphone"]!=nil
# hashPlist.delete("UILaunchStoryboardName~iphone")
# end

# do version synchronize
if run_config["isVersionSynchronizesNeed"]!=nil&&run_config["isVersionSynchronizesNeed"]
if hashPlist["CFBundleVersion"]!=nil
    p "will do version synchronize..."
    hashPlist["CFBundleShortVersionString"]=hashPlist["CFBundleVersion"]
end
end

if run_config["isNeedPortrait"]!=nil&&run_config["isNeedPortrait"]
p "update: add portrait orientation,and make portrait first..."
# resort orientation keys to make portrait first, then, we fix screenLaunch bug in iphone4s on ios8.3
add_orient="UIInterfaceOrientationPortrait"
if hashPlist["UISupportedInterfaceOrientations"]!=nil
temp_List=[add_orient]
temp_List=temp_List+hashPlist["UISupportedInterfaceOrientations"]
hashPlist["UISupportedInterfaceOrientations"]=temp_List
else
hashPlist["UISupportedInterfaceOrientations"]=[add_orient]
end
end


p "update: modify original plist file, add xgsdk info..."
Utils::XGSDK.createHashValue(hashPlist,"xgsdk_channelid",xgsdk_channelid)
Utils::XGSDK.createHashValue(hashPlist,"CFBundleIdentifier",bundle_id)

p "update: Localization_native_development_region..."
if run_config["Localization_native_development_region"]!=nil
Utils::XGSDK.createHashValue(hashPlist,"CFBundleDevelopmentRegion",run_config["Localization_native_development_region"])
else
p "no Localization_native_development_region is configged..."
end

p "update: add key in original plist..."
if run_config["originalPlist"]!=nil
run_config["originalPlist"].each do |k,v|
  config_key = v.split("$")[1]
  value=""
    # 若配置了“$”,则需要读取config.yaml文件
    if config_key!=nil
        config_value = config[config_key]
        value = v.split("$")[0].to_s+config_value.to_s+v.split("$")[2].to_s
    end
Utils::XGSDK.createHashValue(hashPlist,k,value)
end
end

#在info.plist中添加GameCenter key值，以支持gamecenter
if run_config["isGameCenterNeed"]!=nil && run_config["isGameCenterNeed"]
p "will add gamekit key...."
Utils::XGSDK.addGameKitKey(hashPlist)
end

p "update: add url scheme..."
urlTypeList = run_config["urlTypeList"]
for item in urlTypeList
    new_schemes=[]
for i in item["CFBundleURLSchemes"]
    config_key = i.split("$")[1]
    # 若配置了“$”,则需要读取config.yaml文件
    if config_key!=nil
        config_value = config[config_key]
        i = i.split("$")[0].to_s+config_value.to_s+i.split("$")[2].to_s
        new_schemes<<i
    end
end
   item["CFBundleURLSchemes"]=new_schemes
   
#   将CFBundleURLName的参数实例化
CFName_value = item["CFBundleURLName"]
if CFName_value!=nil
       config_key_CFName = CFName_value.split("$")[1]
       # 若配置了“$”,则需要读取config.yaml文件
       if config_key_CFName!=nil
           config_value_CFName = config[config_key_CFName]
        p "CFName value is "+config_value_CFName
           CFName_value = CFName_value.split("$")[0].to_s+config_value_CFName.to_s+CFName_value.split("$")[2].to_s
            item["CFBundleURLName"]=CFName_value
       end
end
end



#p hashPlist["CFBundleURLTypes"]
if hashPlist["CFBundleURLTypes"]!=nil
for urltype in urlTypeList
    is_need_add_flag = true
    for j in hashPlist["CFBundleURLTypes"]
        # 如果已经存在，则不追加
        if ["CFBundleURLName"]==urltype["CFBundleURLName"]
            is_need_add_flag=false
            break
        end
    end
    if is_need_add_flag
        hashPlist["CFBundleURLTypes"]<<urltype
    end
end
else
hashPlist["CFBundleURLTypes"]=urlTypeList
end


if run_config["ios9HttpEnable"]!=nil 
p "add https trans config for iOS9"
hashPlist["NSAppTransportSecurity"]={"NSAllowsArbitraryLoads"=>run_config["ios9HttpEnable"]}
end

if hashPlist["LSApplicationQueriesSchemes"]==nil && run_config["ios9Urlschemes"]!=nil then
p "add urlSchemes config for iOS9"
hashPlist["LSApplicationQueriesSchemes"]=run_config["ios9Urlschemes"] 
elsif  hashPlist["LSApplicationQueriesSchemes"]!=nil && run_config["ios9Urlschemes"]!=nil then
p "modify urlSchemes config for iOS9"
hashPlist["LSApplicationQueriesSchemes"]<<run_config["ios9Urlschemes"] 
end




p "save: plist..."
# proj_file 为原始的plist文件
Xcodeproj::PlistHelper.write(hashPlist,proj_file)


# add xgsdk plist , Notes: This file is not the original plist use by basic target.
p "create: plist..."
temp_hashList=run_config["plistKeyList"]
new_hashList={}
temp_hashList.each do |k,v|
  config_key=v.split("$")[1]
  # p config_key
 if config_key!=nil
  plist_config_value=config[config_key]
  v=plist_config_value
 end
 new_hashList[k]=v
end

new_hashList["xgsdk_commit_hash"]=commit_hash;
Xcodeproj::PlistHelper.write(new_hashList,xgsdk_info_file)
p "xgsdk_info_file generated successfully..."


#-------------------------------------------------------------------------
p ""
p "3: ========  update build phase ========"

p "update: add lib..."
user_lib_List = run_config["user_libs"]

# 添加用户库
for item in user_lib_List
  p item
p res_path+"/lib/"+item
Utils::XGSDK.setBuildPharse(basicTarget,library_group,res_path+"/lib/"+item)
end
# 添加系统库
sys_lib_List = run_config["system_libs"]
for item in sys_lib_List
Utils::XGSDK.setBuildPharse(basicTarget,library_group,system_lib_path+"/"+item)
end


p "update: add framework..."
# 添加用户framework
user_frame_List = run_config["user_frameworks"]
for item in user_frame_List
Utils::XGSDK.setBuildPharse(basicTarget,framework_group,res_path+"/frame/"+item)
end
# 添加系统framework
sys_frame_List = run_config["sys_frameworks"]
for item in sys_frame_List
Utils::XGSDK.setBuildPharse(basicTarget,framework_group,system_framworks_path+"/"+item)
end



if run_config["embbed_frameworks"]!=nil&&run_config["embbed_frameworks"].length > 0
for emb_frame in run_config["embbed_frameworks"]

p "add embed file: "+emb_frame
embed_file=nil
for file in framework_group.files
   if file.name == emb_frame
       embed_file=file
       break
   end
end

copyFile = basicTarget.new_copy_files_build_phase
copyFile.dst_path=""
copyFile.name="Embed Frameworks"
copyFile.dst_subfolder_spec="10"
copyFile.run_only_for_deployment_postprocessing="0"
copyFile.add_file_reference(embed_file,true)


# add code sign attributes
for file in copyFile.files
    p file.file_ref
    if file.file_ref.name == emb_frame
        file.settings={"ATTRIBUTES"=>["CodeSignOnCopy"]}
        break
    end
end

end
end

p "update: add bundle..."
# 添加bundle
user_bundle_List = run_config["user_bundles"]
for item in user_bundle_List
Utils::XGSDK.setResoucePharse(basicTarget,bundle_group,res_path+"/bundle/"+item)
end
Utils::XGSDK.setResoucePharse(basicTarget,bundle_group,xgsdk_info_file)

p "update: add srouce..."
if run_config["source_files"].length >0
    for item in run_config["source_files"]
       Utils::XGSDK.setSourceFilePharse(basicTarget,srouce_group,res_path+"/src/"+item["file_name"])
       
        # 添加编译选项
       for file in basicTarget.source_build_phase.files
           p file.file_ref
           if file.file_ref.name == item["file_name"]
               file.settings={"COMPILER_FLAGS"=>item["complier_flag"]}
               break
           end
       end

    end
end


p "add unity setting if need..."
Utils::XGSDK.makeUnitySetting(project_path,proj,basicTarget)


if run_config["isReplaceIconNeed"]!=nil && run_config["isReplaceIconNeed"]
p "add: icon resouce..."
system "unzip -o ./xgsdk_resource.zip -d #{project_file_path}/.."  
Utils::XGSDK.resetIconPath(basicTarget,xgsdk_channelid)
p "======== end ========"
end

proj.save

