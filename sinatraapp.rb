require 'csv'
require 'json'
require 'savon'

require 'sinatra'




disable = '#FF0000'


before do
    content_type 'application/json'
end
get '/check/:id' do |id|
	msv = id.strip
	client = Savon.client("http://10.1.0.237:8082/Services.asmx?wsdl")
	response = client.request(:tinh_trang_sinh_vien) do
		soap.body = {:masinhvien => msv}
	end
	res_hash = response.body.to_hash
	ls = res_hash[:tinh_trang_sinh_vien_response][:tinh_trang_sinh_vien_result][:diffgram][:document_element]
	if (ls != nil) then ls.to_json 
	else 'null' end
end
get '/:id' do |id|
	puts 'request new'
	nodes = []
links = []
tags = {}
sbjs = {}
deps = {}
courses = {}
names = {}
groups = {}
colors = {}
prev = {}
status = {}
diem = {}
replace = {}
courses2 = {}
mas = 1


	msv = id.strip
	i = 0
	client = Savon.client("http://10.1.0.237:8082/Services.asmx?wsdl")
	response = client.request(:mon_sinh_vien_da_qua) do
		soap.body = {:masinhvien => msv }
	end
	response2 = client.request(:mon_sinh_vien_no) do
		soap.body = {:masinhvien => msv }
	end
	response_courses = client.request(:khung_chuong_trinh) do
		soap.body = {:masinhvien => msv }
	end
	response_replace = client.request(:mon_thay_the) do
		soap.body = {:masinhvien => msv}
	end
	response_dk = client.request(:dieu_kien_truoc_sau) do
		soap.body = {:masinhvien => msv }
	end
	
	res_hash = response.body.to_hash
	res_hash2 = response2.body.to_hash
	res_hash_courses = response_courses.body.to_hash
	res_hash_replace = response_replace.body.to_hash
	res_hash_dk = response_dk.body.to_hash

	ls = res_hash[:mon_sinh_vien_da_qua_response][:mon_sinh_vien_da_qua_result][:diffgram][:document_element]
	if (ls ) then ls = ls[:mon_sinh_vien_da_qua]
	else 
		puts "error1";
		#return '{"error":"error1"} '
	end
	ls2 = res_hash2[:mon_sinh_vien_no_response][:mon_sinh_vien_no_result][:diffgram][:document_element]
	if (ls2) then ls2 = ls2[:mon_sinh_vien_no]
	else 
		puts "error2";
		#return '{"error":"error2"}' 
	end
	ls_courses = res_hash_courses[:khung_chuong_trinh_response][:khung_chuong_trinh_result][:diffgram][:document_element]
	if (ls_courses) then ls_courses = ls_courses[:khung_chuong_trinh]
	else 
		puts "error3";
		return '{"error":"error3"}' 
	end
	ls_replace = res_hash_replace[:mon_thay_the_response][:mon_thay_the_result][:diffgram][:document_element]
	if (ls_replace) then ls_replace = ls_replace[:mon_thay_the]
	else
		puts "error4"
	end
	ls_dk = res_hash_dk[:dieu_kien_truoc_sau_response][:dieu_kien_truoc_sau_result][:diffgram][:document_element]
	if (ls_dk) then ls_dk = ls_dk[:dieu_kien_truoc_sau]
	else 
		puts "error5";
		return '{"error":"error5"}' 
	end

	ls_courses.each do |item|
		temp = item[:ma_mon_hoc].strip
		sbjs[temp] = 0		
		
		status[temp] = {}
		status[temp]['makhoi'] = item[:ma_khoi_kien_thuc].strip
		status[temp]['khoikienthuc'] = item[:ten_khoi_kien_thuc].strip
		status[temp]['tinhtrang'] = disable
		status[temp]['ten'] = item[:ten_mon_hoc].strip
		status[temp]['khoiluong'] = item[:tong_so].strip	
		status[temp]['nhom'] = 1
		if (item[:tu_chon]) then 
			if (item[:so_mon_phai_chon]) then 
				status[temp]['somontuchon'] = item[:so_mon_phai_chon].strip + '/' + item[:tong_so_mon_tu_chon].strip
				if (item[:ten_nhom] ) then 
					status[temp]['tennhom'] = item[:ten_nhom].strip
				else
					status[temp]['tennhom'] = ''
				end
			else
				status[temp]['somontuchon'] = ''
				status[temp]['tennhom'] = ''
			end

			status[temp]['tuchon'] = 1 
		else status[temp]['tuchon'] = 0 
		end
	end
	outside = '#FF9900'
	outside_fail = '#FF99FF'
	if (ls_replace) then 				
		ls_replace.each do |item|	
			
				
			mon1 = item[:ma_mon_hoc1].strip
			puts 'mon1: ' + mon1 

			mon2 = item[:ma_mon_hoc2].strip
			
			if (status[mon1]) then 
				status[mon1]['thaythe'] = mon2			
				replace[mon2] = mon1
			end
		end
	end
	ls_dk.each do |item| 		
		mon1 = item[:ma_mon_hoc1].strip
		mon2 = item[:ma_mon_hoc2].strip

		if (replace[mon1]) then mon1 = replace[mon1] end
		if (replace[mon2]) then mon2 = replace[mon2] end


		if (!deps[mon1]) then deps[mon1] = Array.new end

		deps[mon1].push(mon2)

		if (sbjs[mon1]) then
			sbjs[mon1] = sbjs[mon1] + 1
		else
			puts "error subject " + mon1
			sbjs[mon1] = 1
		end

		if (sbjs[mon2]) then
			sbjs[mon2] = sbjs[mon2] + 1		
		else
			puts "error subject2: " + mon2
			sbjs[mon2] = 1
		end

		
	end
	ls_dk.each do |item| 
		mon1 = item[:ma_mon_hoc1].strip
		mon2 = item[:ma_mon_hoc2].strip		
		mas = [ro(status, deps, mon1, 1),mas].max		
	end



	pass = '#006666'	
	fail = '#CCCC00'
	if (ls ) then
		ls.each do |item|
			temp = item[:ma_mon_hoc].strip
			if (status[temp] ) then 
				status[temp]['tinhtrang'] = pass			
			else 
				puts 'No pass: ' + temp
			end
		end
	end
	if (ls2) then 
		ls2.each do |item|
			temp = item[:ma_mon_hoc].strip
			if (status[temp]) then 
				status[temp]['tinhtrang'] = fail			
			else 
				puts 'No fail: ' + temp
			end	
		end
	end
	i = 0
	j = 0
	sbjs.each do |k,v|
		if (v > 0) then 		
			courses[k] = i
			i = i + 1		
		else
			courses2[k] = j
			j = j + 1
		end
	end

	courses2_json = []
	courses2.each do |k,v|
		courses2_json.push({"name" => status[k]['ten']})
	end
	
	courses.each do |k,v|		
			if (status[k]['makhoi']=='4') then 
				status[k]['nhom'] = mas + 1
				ro(status, deps, k, mas + 1)				
			end 			
	end

	ls_dk.each do |item| 
		links.push({"source" => courses[item[:ma_mon_hoc1].strip],
					"target" => courses[item[:ma_mon_hoc2].strip]})		

	end

	enable = '#9900FF'

	courses.each do |k, v|
		temp = deps[k]
		if (temp) then 
				status[k]['leaf'] = 0		
		else
			status[k]['leaf'] = 1
		end
		if (status[k]['nhom'] == 1 and status[k]['tinhtrang'] == disable) then 
			status[k]['tinhtrang'] = enable
		end
		if (status[k]['tinhtrang'] == pass or status[k]['tinhtrang'] == fail) then 			
			if (temp) then 						
				temp.each do |item|
					if (status[item]['tinhtrang'] == disable) then status[item]['tinhtrang'] = enable end
				end
			end
		end
	end

	sbjs.each do |k,v|
		if (v > 0) then 			
			nodes.push({"name" => status[k]['ten'], 
					"group" => status[k]['nhom'], 
					"color" => status[k]['tinhtrang'],
					"mamon" => k,
					"tuchon" => status[k]['tuchon'],
					"tennhom" => status[k]['tennhom'],
					"somontuchon" => status[k]['somontuchon'],
					"khoikienthuc" => status[k]['khoikienthuc'],
					"leaf" => status[k]['leaf'],
					"dvht" => status[k]['khoiluong'],
					"thaythe" => (status[k]['thaythe']) ?   status[k]['thaythe'] : '' })
		end
	end

	tags["nodes"] = nodes
	tags["links"] = links
	tags["other"] = courses2_json

	return tags.to_json
end

def ro(status, deps, item, mas)
	if (!deps[item]) then
		return status[item]['nhom']
	  end		 	
		deps[item].each do |it|
			status[it]['nhom'] = [status[it]['nhom'],status[item]['nhom'] + 1].max				
			tmp = ro(status, deps, it, status[it]['nhom'])		
			mas = [tmp, mas].max
		end	
	return mas	
end

def ri(status, deps, item)	
	if (!deps[item]) then return 
	else
		temp = status[item]['tinhtrang'].strip
		if (temp == pass or temp == fail) then 
			deps[item].each do |it|
				if (status[it]['tinhtrang'].strip == disable) then
					status[it]['tinhtrang'].strip = enable		
					puts it 											
				else 
					ri(status, deps, it)
				end
			end
		end
	end
end

 
 