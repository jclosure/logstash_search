class Logstash

  
  
  def self.mquery(params, size: 10000)

    #binding.pry
    # use an alias
    result = params[:es].msearch([{index: params[:index]},{index: params[:index2]},
      {                   
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
      "size": params[:size],
      "sort": [
        {
          "@timestamp": {
            "order": "desc",
            "ignore_unmapped": true
          }
        },
        {
          "@timestamp": {
            "order": "desc",
            "ignore_unmapped": true
          }
        }
      ]

      # SNIP QUERY END
      }] 
    )

    result
  end

  
  
  def self.query(params, size: 10000)

    #binding.pry
    # use an alias
    result = params[:es].index(params[:index]).search(

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
      "size": params[:size],
      "sort": [
        {
          "@timestamp": {
            "order": "desc",
            "ignore_unmapped": true
          }
        },
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
  def self.sort_by_date

    field_name = "@timestamp"
    
    entries.results.sort! do |a,b|
      begin
        if a.key?(field_name) && b.key?(field_name) 
          DateTime.parse(a[field_name]) <=> DateTime.parse(b[field_name])
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
