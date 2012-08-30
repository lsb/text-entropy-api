require 'json/ext'
require 'active_record'
require 'andand'
ARb = ActiveRecord::Base
ARb.establish_connection(:adapter => "sqlite3", :database => "ngrams.db")

class Gram1 < ARb ; end
class Gram2 < ARb ; end
class Gram3 < ARb ; end
class Gram4 < ARb ; end
class Gram5 < ARb ; end

Order = {
  1 => lambda { Gram1.first.andand.a_tot },
  2 => lambda {|a| Gram2.find_by_a(a).andand.b_tot },
  3 => lambda {|a,b| Gram3.find_by_a_and_b(a,b).andand.c_tot },
  4 => lambda {|a,b,c| Gram4.find_by_a_and_b_and_c(a,b,c).andand.d_tot },
  5 => lambda {|a,b,c,d| Gram5.find_by_a_and_b_and_c_and_d(a,b,c,d).andand.e_tot }
}

def Prefetch(ids, order)
  (0...ids.length).map {|index|
    start = index - (order-1)
    finish = index - 1
    start >= 0 ? Order[order].call(*ids[start..finish]) : nil
  }
end

def Multiget(ids, order, ngrams)
  JSON.fast_generate(ngrams.each_with_index.map {|ngram, index|
    if ngram.nil?
      [{"continues" => false, "word" => "", "value" => 1},
       {"continues" => true, "word" => ids[index], "value" => 0}]
    else
      potential_lasts = JSON.parse(ngram)

      original_last_id = ids[index]
      original_last_id_str = original_last_id.to_s
      potential_lasts[original_last_id_str] = "0" unless potential_lasts.has_key?(original_last_id_str)

      total_instance_count = potential_lasts.values.map(&:to_f).inject(&:+)

      potential_lasts.map {|last_id, last_instance_count|
        last_id = last_id.to_i
        last_instance_count = last_instance_count.to_f
        {"continues" => last_id == original_last_id,
         "word" => last_id,
         "value" => (last_instance_count / total_instance_count).round(6)}
      }
    end
  })
end
