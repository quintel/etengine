require 'highline/import'
require 'term/ansicolor'
include Term::ANSIColor

namespace :bulk_update do
  desc "This shows the changes that would be applied to gqueries. Pass FORCE=TRUE to update records"
  task :gquery_replace => :environment do
    bootstrap

    @gqueries = Gquery.contains(@from)
    @gqueries.each do |g|
      puts "GQuery #{g.id}".yellow.bold
      puts "Query was: #{highlight(g.query, @from)}"
      g.query = g.query.gsub(@from, @to)
      puts "Query will be: #{highlight(g.query, @to)}"
      puts
      if @force
        puts "Saving record!".green
        g.save
      end
    end
  end

  desc "This shows the changes that would be applied to inputs. Pass FORCE=TRUE to update records"
  task :input_replace => :environment do
    bootstrap
    @inputs = Input.embedded_gql_contains(@from)
    @inputs.each do |i|
      puts "Input #{i.id}".yellow.bold
      [:start_value_gql, :min_value_gql, :max_value_gql, :attr_name].each do |field|
        value = i.send(field)
        next if value.blank?
        next unless value.include?(@from)
        puts "#{field} was: #{highlight(value, @from)}"
        i.send("#{field}=", value.gsub(@from, @to))
        puts "#{field} will be: #{highlight(i.send(field), @to)}"
      end
      puts
      if @force
        puts "Saving record!".green
        i.save
      end
    end
  end

  def bootstrap
    @from  = ENV["FROM"]
    @to    = ENV["TO"]
    @force = ENV["FORCE"] == "TRUE"

    if @force
      unless HighLine.agree("You know what you're doing, right? [y/n]")
        puts "Bye"; exit
      end
    end

    if @from.blank? || @to.blank?
      puts "Missing FROM/TO attribute"; exit
    end
  end

  def highlight(text, token)
    text.gsub(token, token.red)
  end

  task :update_scenarios => :environment do
    @update_records = HighLine.agree("You want to update records, right? [y/n]")
    counter = 0
    Scenario.order('id').find_each(:batch_size => 100) do |s|
      puts "Scenario ##{s.id}"

      if s.area_code.blank? || counter == 0
        puts "ERROR: no area code. Skipping Scenario"
        counter += 1
        next
      end

      begin
        inputs = s.user_values
      rescue
        puts "Error!"
        next
      end
      # ...
      # ...
      # to add or change a new input value:
      # inputs[123] = 567.789789
      #
      # to remove a slider values
      # inputs.delete(123)
      #
      # to get a value
      # inputs[123]
      #
      # Important: slider ids must be integers!
      # inputs["123"] != inputs[123]
      #
      # To see what's going on
      # inputs.to_yaml

      ##########################################################
      # Following lines describe the changes of scenarios in the
      # deploy of July 10 2012
      defaults = {1 => 0.0, 6 => 0.0, 11 => 0.0, 12 => 0.0, 14 => 0.0, 16 => 0.0, 17 => 0.0, 18 => 0.0, 19 => 0.0, 43 => 20.0, 44 => 0.0, 47 => 0.0, 48 => 0.0, 51 => 0.0, 52 => 1.759974, 57 => 0.0, 58 => 0.0, 59 => 0.0, 114 => 0.0, 115 => 0.0, 121 => 0.0, 126 => 0.0, 127 => 0.0, 129 => 0.0, 131 => 0.0, 132 => 0.0, 133 => 0.0, 134 => 0.0, 136 => 0.0, 137 => 0.0, 138 => 85.0, 139 => 0.0, 140 => 0.0, 141 => 0.0, 142 => 0.0, 143 => 0.0, 144 => 0.0, 145 => 0.0, 146 => 0.0, 147 => 47.152636, 148 => 48.126123, 157 => 0.0, 158 => 100.0, 159 => 0.0, 169 => 0.0, 170 => 0.0, 171 => 0.0, 178 => 83.916083, 179 => 16.666666, 180 => 0.0, 181 => 0.0, 182 => 0.0, 183 => 0.0, 185 => 0.0, 186 => 0.0, 187 => 0.0, 188 => 0.0, 193 => 0.0, 194 => 0.0, 195 => 0.0, 196 => 5393.1818, 197 => 0.0, 198 => 0.0, 202 => 0.0, 203 => 0.0, 204 => 0.0, 205 => 0.0, 206 => 50.0, 207 => 0.0, 208 => 0.0, 210 => 60.0, 211 => 30.0, 212 => 50.0, 213 => 0.0, 214 => 0.0, 216 => 37.647787, 217 => 29.750778, 218 => 3.3930112, 219 => 0.4954397, 220 => 0.0, 221 => 0.0, 223 => 13.173528, 225 => 0.635429, 227 => 0.3862728, 228 => 0.104398, 229 => 0.0, 230 => 0.0, 231 => 0.0, 232 => 0.0, 233 => 13.737373, 234 => 3.2088979, 238 => 4.5715361, 239 => 0.1497037, 240 => 0.0, 241 => 0.0, 242 => 0.0, 245 => 80.0, 246 => 28.281435, 247 => 0.0, 248 => 1.2426933, 250 => 3.3914141, 251 => 0.0, 253 => 0.322704, 254 => 0.0, 255 => 0.0, 256 => 4.8282828, 257 => 5.1045918, 258 => 0.0, 259 => 0.31875, 260 => 0.0, 261 => 0.5984861, 263 => 419.58041, 264 => 83.333333, 265 => 68.686868, 266 => 3.6999999, 267 => 0.0, 270 => 0.0, 271 => 11.690721, 272 => 7.41075, 274 => 0.0, 275 => 4017.4505, 276 => 4.2642393, 277 => 0.0, 279 => 4017.4505, 281 => 7.8874563e6, 282 => 110967.24, 283 => 4983.511, 289 => 31330.64, 290 => 72737.443, 291 => 0.8898758, 292 => 98.544176, 293 => 1.4558239, 294 => 96.958812, 295 => 3.0411879, 298 => 0.0, 299 => 0.0, 313 => 0.0, 315 => 0.0, 316 => 0.0, 317 => 0.0030104, 321 => 0.0, 322 => 122.08775, 324 => 7.41075, 325 => 3023.581, 326 => 28.712982, 327 => 57.418935, 328 => 0.0, 333 => 82.100886, 335 => 0.0, 336 => 1.0, 337 => 2.5, 338 => 0.0748925, 339 => 0.0374462, 340 => 2.55678, 341 => 100.0, 343 => 0.0, 344 => 0.0, 346 => 13.578585, 347 => 7.0920372, 348 => 0.9046521, 351 => 0.0748925, 352 => 0.0030104, 353 => 100.0, 354 => 59.918324, 355 => 16.03267, 356 => 8.016335, 357 => 16.03267, 359 => 0.0, 360 => 0.0, 361 => 0.0, 362 => 0.0, 363 => 0.0, 364 => 0.0, 366 => 0.0, 368 => 0.0, 370 => 0.0, 371 => 0.0, 372 => 0.0, 373 => 0.0, 374 => 0.0, 375 => 0.0, 376 => 0.0, 377 => 0.0, 378 => 0.0, 381 => 1.0, 382 => 1.6, 383 => 84.175631, 385 => 0.0, 386 => 5.0903814, 387 => 1.01626, 388 => 1.0109924, 389 => 0.0188546, 390 => 3.22, 391 => 0.0, 392 => 0.0, 393 => 100.0, 394 => 2.0077333, 395 => 2.5, 396 => 10.0, 397 => 20.0, 398 => 0.0, 400 => 75.0, 401 => 24.0, 402 => 1.0, 403 => 26.489399, 404 => 20.46843, 405 => 0.2415862, 406 => 0.0, 408 => 0.0, 409 => 3.4601463, 411 => 0.0615575, 412 => 0.0, 413 => 0.0, 414 => 206883.27, 415 => 4.9450755, 416 => 0.0, 420 => 0.0, 421 => 2.3840614, 422 => 0.0, 423 => 100.0, 424 => 0.0, 425 => 100.0, 426 => 0.0, 427 => 0.0, 428 => 7.0, 429 => 93.0, 430 => 0.0, 431 => 0.0, 432 => 0.0, 433 => 0.0, 435 => 0.0, 436 => 0.0, 437 => 0.0, 439 => 0.0, 441 => 9.1223511, 443 => 0.0, 444 => 0.0, 445 => 0.0, 446 => 76.945316, 447 => 0.0, 448 => 0.0, 488 => 0.0602653, 489 => 99.939734, 490 => 525.93749, 491 => 2713.1313, 492 => 3862.6262, 494 => 1258.7412, 495 => 250.0, 496 => 206.0606, 497 => 37.0, 498 => 0.0, 499 => 649.48453, 500 => 83.75, 501 => 0.0, 502 => 0.0, 503 => 0.0, 504 => 258.16326, 505 => 0.0, 506 => 0.0, 507 => 0.0, 508 => 0.0, 509 => 1687.2727, 510 => 4083.6734, 511 => 0.0, 512 => 6575.8853, 513 => 0.0, 514 => 0.0, 515 => 0.0, 516 => 3373.0612, 517 => 478.78893, 519 => 241.0, 521 => 411.52993, 522 => 0.0, 523 => 1993.1725, 525 => 10121.583, 527 => 0.0, 528 => 165715.22, 529 => 24783.622, 530 => 3144.9206, 531 => 301.66734, 532 => 0.0, 533 => 0.0, 534 => 0.0, 535 => 421.75, 537 => 2601.5483, 538 => 0.0, 540 => 7.5639448, 541 => 315.01754, 544 => 0.0, 545 => 5865.0, 546 => 421.75, 547 => 3727.7027, 548 => 12.784931, 549 => 0.0, 551 => 2.0597394, 552 => 0.0, 553 => 0.0, 554 => 0.0, 556 => 1278.4931, 557 => 0.0, 558 => 0.0, 559 => 0.0, 560 => 100.0, 561 => 92.417914, 562 => 0.0, 563 => 26.3, 564 => 16.9, 565 => 15.3, 566 => 8.8, 567 => 0.0, 568 => 20.3, 569 => 12.4, 570 => 0.0, 571 => 90.0, 572 => 5.0, 573 => 0.0, 574 => 0.0, 575 => 5.0, 576 => 0.0, 577 => 0.0, 578 => 100.0, 579 => 0.0, 580 => 0.0, 581 => 7.5820854, 582 => 3.0404083, 583 => 1.4421768, 584 => 0.0, 1000 => 2040.0, 1001 => 2040.0, 1002 => 2040.0, 1003 => 2040.0, 1004 => 2040.0, 1005 => 0.0, 593 => 0.0}

      # Sliders in HHs hot water should add up to 100%
      share_group_inputs = [421, 420, 444, 445, 446, 347, 439, 346, 435, 443]
      sum = 0
      share_group_inputs.each do |element|
        inputs[element] = defaults[element] if inputs[element].nil?
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% BEFORE scaling
      if !(sum).between?(99.9, 100.1)
          puts "Error! Share group of HHs hot water is not 100% in scenario, but is " + (sum).to_s
      end

      if sum>0.0

        factor = sum/100.0
        inputs[446]=(inputs[446]/factor)
        inputs[421]=(inputs[421]/factor)
        inputs[420]=(inputs[420]/factor)
        inputs[444]=(inputs[444]/factor)
        inputs[445]=(inputs[445]/factor)
        inputs[347]=(inputs[347]/factor)
        inputs[439]=(inputs[439]/factor)
        inputs[346]=(inputs[346]/factor)
        inputs[435]=(inputs[435]/factor)
        inputs[443]=(inputs[443]/factor)
  
        if !(inputs[446] + inputs[421] + inputs[420] + inputs[444] + inputs[445] + inputs[347] + inputs[439] + inputs[346] + inputs[435] + inputs[443]).round(1).between?(99.9, 100.1)
          puts "Error! Sum of HHs HW = " + (inputs[446] + inputs[421] + inputs[420] + inputs[444] + inputs[445] + inputs[347] + inputs[439] + inputs[346] + inputs[435] + inputs[443]).to_s
          exit 
        end
      end
  
      # Sliders in HHs space heating should add up to 100%
      share_group_inputs = [333, 338, 51, 582, 340, 375, 317, 52, 441, 248, 411]
      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] = defaults[element] if inputs[element].nil?
        #puts "#{element} " + inputs[element].to_s
        sum = sum + inputs[element]
      end

      # Check if the share group adds up to 100% BEFORE scaling
      inputs[48] = defaults[48] if inputs[48].nil?
      inputs[339] = defaults[339] if inputs[339].nil?
      if !(sum + inputs[339] + inputs[48] ).between?(99.9, 100.1)
          puts "Error! Share group of HHs space heating is not 100% in scenario, but is " + (sum + inputs[339] + inputs[48]).to_s
          #errorFile << puts "Error! Share group of HHs space heating is not 100% in scenario, but is " + (sum + inputs[339] + inputs[48]).to_s
      end
        
      # HHs heatpump add-on
      inputs[339] = (inputs[339] / 0.6).round(1) unless inputs[339].nil?

      # HHs solar thermal panel
      demand_space_heating = 298.91
      demand_hot_water = 96.17
      inputs[48] = defaults[48] if inputs[48].nil?
      inputs[348] = (( inputs[348] * demand_hot_water + inputs[48] * demand_space_heating ) / ( 0.5 * demand_hot_water + 0.15 * demand_space_heating )).round(1)  unless inputs[348].nil?

      if sum>0.0

        factor = sum/100.0
        inputs[333] = (inputs[333]/factor)
        inputs[338] = (inputs[338]/factor)
        inputs[51 ] = (inputs[51 ]/factor)
        inputs[582] = (inputs[582]/factor)
        inputs[340] = (inputs[340]/factor)
        inputs[375] = (inputs[375]/factor)
        inputs[317] = (inputs[317]/factor)
        inputs[52 ] = (inputs[52 ]/factor)
        inputs[441] = (inputs[441]/factor)
        inputs[248] = (inputs[248]/factor)
        inputs[411] = (inputs[411]/factor)

        if !(inputs[333] + inputs[338] + inputs[51 ] + inputs[582] + inputs[340] + inputs[375] + inputs[317] + inputs[52 ] + inputs[441] + inputs[248] + inputs[411]).between?(99.9, 100.1)
          puts "Error! Sum of HHs SH= " + (inputs[333] + inputs[338] + inputs[51 ] + inputs[582] + inputs[340] + inputs[375] + inputs[317] + inputs[52 ] + inputs[441] + inputs[248] + inputs[411]).to_s
          exit 
        end
      end


      # Sliders in Buildings district heating should add up to 100%
      share_group_inputs = [386, 388, 385, 593]
      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] = defaults[element] if inputs[element].nil?
        #puts "#{element} " + inputs[element].to_s
        sum = sum + inputs[element]
      end

      # This is the new district heating input
      inputs[585] = sum.round(1)

      if sum>0.0

        share_group_inputs.each do |element|
          inputs[element] = 0.0 if inputs[element].nil?
        end

        factor = sum/100.0
        inputs[386]=(inputs[386]/factor)
        inputs[388]=(inputs[388]/factor)
        inputs[385]=(inputs[385]/factor)
        inputs[593]=(inputs[593]/factor)
      end


      # Sliders in Buildings space heating should (still) add up to 100%
      share_group_inputs = [383, 394, 390, 387, 389, 409, 406, 585]
      sum = 0.0
      share_group_inputs.each do |element|
        inputs[element] = defaults[element] if inputs[element].nil?
        #puts "#{element} " + inputs[element].to_s
        sum = sum + inputs[element]
      end
      
      if sum>0.0 
        if !(sum).round(1).between?(99.9, 100.1)
          puts "Error! Sum of inputs Buildings SH = " + sum.to_s
        end
      end 

      # Buildings insulation
      if inputs[381].nil?
        inputs[381]= inputs[382] unless inputs[382].nil?
      else
        inputs[381]=([inputs[381], inputs[382]].min).round(1) unless inputs[382].nil?
      end

      # Transport fuels should have gasoline - > 0 (new slider)
      inputs[588]=0.0

      # Heavy fuel oil should be zero (new slider)
      inputs[589]=0.0

      # Delete old inputs
      inputs.delete(48)
      inputs.delete(382)

      # Cost slider for fuel cell should be initialized at the correct
      # cost (depends on start-year of scenario)
      if s.end_year == 2013
        inputs[595] = -20.0
      elsif s.end_year == 2014
        inputs[595] = -40
      elsif s.end_year == 2015
        inputs[595] = -60.0
      elsif s.end_year.between?(2016,2019)
        inputs[595] = -66.0
      elsif s.end_year.between?(2020,2029)
        inputs[595] = -70.0
      elsif s.end_year.between?(2030,2039)
        inputs[595] = -74.0
      elsif s.end_year.between?(2040,2050)
        inputs[595] = -78.0
      end

      # Input for the new co-firing wood pellets slider based
      # Values are determined based on user input of number of co-firing plants and coal plants
      # Set to defaults if nil (not touched)
      inputs[250] = defaults[250] if inputs[250].nil?  # number_of_pulverized_coal
      inputs[251] = defaults[251] if inputs[251].nil?  # number_of_pulverized_coal CCS
      inputs[551] = defaults[551] if inputs[551].nil?  # central cola CHP
      inputs[261] = defaults[261] if inputs[261].nil?  # co-firing wood pellets
      inputs[559] = defaults[559] if inputs[559].nil?  # bio-coal share


      sum_coal_plants = inputs[250]+inputs[251]+inputs[551]+inputs[261]
      sum_co_firing_plants = inputs[261]

      if sum_coal_plants == 0.0
        inputs[596] = 0.0 # co-firing share
        inputs[559] = 0.0 # bio-coal
        inputs[560] = 100.0 # coal share
      elsif sum_co_firing_plants >= 0.5*sum_coal_plants
        inputs[596] = 50.0 # Co-firing wood pellets slider is capped at 50%
        if inputs[559] >= 50.0
          inputs[559] = 50.0
          inputs[560] = 0.0
        else
          inputs[560] = (50.0 - inputs[559]).round(1)
        end
      else
        inputs[596] = (100.0*sum_co_firing_plants/sum_coal_plants).round(1)
        if  100.0 - inputs[559] - inputs[596] < 0.0
          inputs[559] = (100.0 - inputs[596]).round(1)
          inputs[560] = 0.0
        else
          inputs[560] = (100.0 - inputs[559] - inputs[596]).round(1)
        end
      end

      #puts inputs

      if (inputs[559] + inputs[596] + inputs[560]).round(1) != 100.0
        puts "Error! Sum of 559, 596 and 560 = " + (inputs[559] + inputs[596] + inputs[560]).to_s
        exit
      end

      # Rounding all inputs
      inputs.each do |x|
        x[1] =x[1].round(1) unless x[1].nil?
      end

      ################ END ####################################

      if @update_records
        #puts "saving"

        #s.update_attributes!(:user_values => inputs)
      end

      counter += 1
      exit if s.id == 47861
    end
  end
end
