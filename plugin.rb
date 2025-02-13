# name: CWHQ-Discourse-Bot
# about: This plugin adds extra functionality to the @system user on a Discourse forum.
# version: 1.3
# author: Qursch
# url: https://github.com/Qursch/CWHQ-Discourse-Bot

require 'date'

courses = Hash.new
courses = {
    36 => "e13_real_prog_00",
    37 => "e14_minecraft_00",
    45 => "e21_prog_concepts_00",
    31 => "e22_wd1_00",
    58 => "e23",
    46 => "e24",
    13 => "intro_prog_py_00",
    14 => "m12_html_css_00",
    15 => "m13_js_00",
    16 => "M14_vr_00",
    17 => "m21_ui_00",
    18 => "m22_database_00",
    47 => "m23_api_00",
    48 => "m24_omg_00",
    53 => "m31_flask_00",
    54 => "m32",
    55 => "m33",
    56 => "m34",
    20 => "h11_intro_python_00",
    21 => "h12_web_dev_00",
    22 => "h13_ui_00",
    23 => "h14_api_00",
    49 => "h21_framework_00",
    50 => "h22_mvc_00",
    51 => "h23",
    52 => "h24",
    59 => "h31",
    60 => "h32",
    61 => "h33",
    62 => "h34",
    11 => false,
    57 => false
}

def get_link(id, username, hash)
    if id == 11 || id == 57 then
        return "`https://scratch.mit.edu/projects/00000000`" 
    else
        if !hash[id].nil? then
            return "`https://" + username + ".codewizardshq.com/" + hash[id] + "/project`"
        end
    end
    return false
end

def create_post(topicId, text)
    post = PostCreator.create(
        Discourse.system_user,
        skip_validations: true,
        topic_id: topicId,
        raw: text)
    unless post.nil?
        post.save(validate: false)
    end
end

def closeTopic(id, message)
    topic = Topic.find_by(id: id)               
    topic.update_status("closed", true, Discourse.system_user, {message: message})
end

after_initialize do
   
    # Missing Link
    DiscourseEvent.on(:topic_created) do |topic|
        
        link = get_link(topic.category_id, topic.user.username, courses)
        if link then
        
            newTopic = Post.find_by(topic_id: topic.id, post_number: 1)
            topicRaw = newTopic.raw
            lookFor = topic.user.username + ".codewizardshq.com"

            if topicRaw.downcase.include?(lookFor + "/edit") then
                includesReq = "editor link"
                text = "Hello @" + topic.user.username + ", it appears that the link that you provided goes to the editor, and not your project. Please open your project and use the link from that tab. This may look like " + link + "."
                create_post(topic.id, text)
            elsif !topicRaw.downcase.include?(lookFor) && !topicRaw.downcase.include?("cwhq-apps.com") then
                text = "Hello @" + topic.user.username + ", it appears that you did not provide a link to your project. In order to recieve the best help, please edit your topic to contain a link to your project. This may look like " + link + "."
                create_post(topic.id, text)
            end

        end
    end


    DiscourseEvent.on(:post_created) do |post|
        
        if post.post_number != 1 && post.user_id != -1 then

            # Close Topic Command        
            raw = post.raw
            oPost = Post.find_by(topic_id: post.topic_id, post_number: 1)

            if raw[0, 13].downcase == "@system close" then
                
                group = Group.find_by(id: post.user.primary_group_id)
                topic = post.topic
                id = topic.category_id
                if (!post.user.primary_group_id.nil? && group.name = "Helpers") || (oPost.user.name == post.user.name && !courses[id].nil?) then
                    closeTopic(post.topic_id, raw[14..raw.length])
                end  
            end
        end
    end
end
