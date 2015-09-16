
require 'date'
require_relative 'extensions'


class Logstash

  def self.generate_indices(starting, ending)

    date_from  = DateTime.parse(starting)
    date_to    = DateTime.parse(ending)
    date_range = date_from..date_to

    date_days = date_range.map {|d| Date.new(d.year, d.month, d.day)}.uniq
    date_days.map {|d| d.strftime "logstash-%Y.%m.%d"}
  end
  
  def self.query(params, size: 10000)

    es = params.es
    
    index_name = params[:index] || Logstash.generate_indices(params.starting, params.ending).join(",")

    puts "searching index: #{index_name}"
    
    result = es.index(index_name).search(

      # SNIP QUERY BEGIN
      
      "query": {
        "filtered": {
          "query": {
            "bool": {
              "should": [
                {
                  "query_string": {
                    "query": params[:word]
                  }
                }
              ]
            }
          },
          "filter": {
            "bool": {
              "must": [
               {
                  "range": {
                    "@timestamp": {
                      "from": params[:starting],
                      "to": params[:ending]
                    }
                  }
                }
              ]
            }
          }
        }
      },
      "size": size,
      "sort": [
        {
          "@timestamp": {
            "order": "desc",
            "ignore_unmapped": true
          }
        }
      ]

      # SNIP QUERY END  
    )

    result
  end

  
  # LOCAL SORT
  def self.sort_by_date results, date_key

    #date_key = "@timestamp"
    
    results.sort! do |a,b|
      begin
        if a.key?(date_key) && b.key?(date_key) 
          DateTime.parse(a[date_key]) <=> DateTime.parse(b[date_key])
        else
          1
        end
      rescue => error
        puts "#{error.class} and #{error.message}"
        1
      end
    end
  end

end
