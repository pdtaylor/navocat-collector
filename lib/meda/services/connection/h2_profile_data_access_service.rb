require 'java'
require 'logger'
require 'meda'


require_relative '../../../h2-1.3.176.jar'
require_relative "../../../javassist-3.19.0-GA.jar"
require_relative "../../../slf4j-api-1.7.10.jar"
require_relative "../../../slf4j-simple-1.7.10.jar"
#require_relative "../../../HikariCP-2.3.1.jar"
require_relative "../../../HikariCP-java6-2.3.1.jar"
require_relative "h2_connection_pool.rb"

java_import java.sql.DriverManager
java_import java.sql.PreparedStatement
java_import java.sql.Connection

module Meda

  class H2ProfileDataAccessService

  	def initialize(db_conn_url)
      @db_conn_pool = Meda::H2ConnectionPoolService.new(db_conn_url)
      createSchema

    end

    def createSchema
      begin
      connection = @db_conn_pool.get_connection()
        statement = connection.createStatement();
        statement.executeUpdate("DROP TABLE Profiles IF EXISTS")
        statement.executeUpdate("CREATE TABLE Profiles (profile_id VARCHAR(255) PRIMARY KEY, age VARCHAR(255), gender VARCHAR(255), memberType VARCHAR(255),Option VARCHAR(255),heathAndConsumerSegmentation VARCHAR(255),healthSegmentation VARCHAR(255),consumerSegmentation VARCHAR(255))")
        statement.executeUpdate("DROP TABLE ProfileLookups IF EXISTS")
        statement.executeUpdate("CREATE TABLE ProfileLookups (lookup_key VARCHAR(255) PRIMARY KEY, profile_id VARCHAR(255))")
  
      rescue Exception => error
        puts "!! ERROR CREATING TABLES !! -- #{error.message} -- #{error.backtrace}"
      ensure
        puts "" 
        puts "********** createSchema - Before connection closed *********"
        @db_conn_pool.get_stats
        statement.close()
        connection.close()   
        puts "********** createSchema - Afters connection closed *********"
        @db_conn_pool.get_stats
      end      
    end

    def updateProfile(profile_id, profile_params)

      begin
          connection = @db_conn_pool.get_connection()
          preparedStatement = connection.prepareStatement("UPDATE Profiles SET age=?, gender=?, memberType=?, Option=?, heathAndConsumerSegmentation=?, healthSegmentation=?, consumerSegmentation=? WHERE profile_id=?")
          preparedStatement.setString(1, profile_params[:age].to_s || "") 
          preparedStatement.setString(2, profile_params[:gender].to_s || "")
          preparedStatement.setString(3, profile_params[:memberType].to_s || "")
          preparedStatement.setString(4, profile_params[:Option].to_s || "")
          preparedStatement.setString(5, profile_params[:heathAndConsumerSegmentation].to_s || "")
          preparedStatement.setString(6, profile_params[:healthSegmentation].to_s || "")
          preparedStatement.setString(7, profile_params[:consumerSegmentation].to_s || "")
          preparedStatement.setString(8, profile_id)
          preparedStatement.executeUpdate()     
          return true 
      rescue Exception => error
        puts "!! ERROR UPDATING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      ensure
        puts "" 
        puts "********** updateProfile - Before connection closed *********"
        @db_conn_pool.get_stats
        preparedStatement.close()
        connection.close() 
        puts "********** updateProfile - Afters connection closed *********"
        @db_conn_pool.get_stats
      end    
    end


  	def addProfile(profile_id)
  		begin
    			connection = @db_conn_pool.get_connection()
          preparedStatement = connection.prepareStatement("INSERT INTO Profiles(profile_id) VALUES (?)")
    			preparedStatement.setString(1, profile_id)
    	    preparedStatement.executeUpdate()
          return true	
  		rescue Exception => error

   			puts "!! ERROR ADDING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      ensure
        puts ""    
        puts "********** addProfile - Before connection closed *********"
        @db_conn_pool.get_stats
        preparedStatement.close()
        connection.close() 
        puts "********** addProfile - Afters connection closed *********"
        @db_conn_pool.get_stats
  		end  
  	end

    def getProfile(profile_id)
      begin 
          connection = @db_conn_pool.get_connection()
          preparedStatement = connection.prepareStatement("SELECT * FROM Profiles WHERE profile_id=?")  
          preparedStatement.setString(1, profile_id)   
          resultSet = preparedStatement.executeQuery()

          if(!resultSet.isBeforeFirst())
            return false
          end

          while (resultSet.next()) 
            age                            = resultSet.getString("age")
            gender                         = resultSet.getString("gender")
            memberType                     = resultSet.getString("memberType")
            opt                            = resultSet.getString("Option")
            heathAndConsumerSegmentation   = resultSet.getString("heathAndConsumerSegmentation")
            healthSegmentation             = resultSet.getString("healthSegmentation")
            consumerSegmentation           = resultSet.getString("consumerSegmentation")
          end

          profile = ActiveSupport::HashWithIndifferentAccess.new({
            :id => profile_id,
            :age => age,
            :gender => gender,
            :memberType => memberType,
            :Option => opt,
            :heathAndConsumerSegmentation => heathAndConsumerSegmentation,
            :healthSegmentation => healthSegmentation,
            :consumerSegmentation => consumerSegmentation
          })  

      rescue Exception => error
        puts "!! ERROR READING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      ensure
        puts ""    
        puts "********** getProfile - Before connection closed *********"
        @db_conn_pool.get_stats
        resultSet.close()          
        preparedStatement.close()
        connection.close()   
        puts "********** getProfile - Afters connection closed *********"
        @db_conn_pool.get_stats
      end  
    end

    def removeProfile(profile_id)
      begin
          connection = @db_conn_pool.get_connection()
          preparedStatement = connection.prepareStatement("DELETE FROM Profiles WHERE profile_id (?)")
          preparedStatement.setString(1, profile_id)
          preparedStatement.executeUpdate()
          return true 
      rescue Exception => error
        puts "!! ERROR REMOVING PROFILE !! -- #{error.message} -- #{error.backtrace}"
      ensure      
        preparedStatement.close()
        connection.close()
      end  
    end

    def removeProfileLookUp(profile_id)
      begin
          connection = @db_conn_pool.get_connection()
          preparedStatement = connection.prepareStatement("DELETE FROM ProfileLookups WHERE profile_id (?)")
          preparedStatement.setString(1, profile_id)
          preparedStatement.executeUpdate()
          return true 
      rescue Exception => error
        puts "!! ERROR REMOVING PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      ensure      

        preparedStatement.close()
        connection.close()
      end  
    end

    def addProfileLookup(lookup_key, lookup_value)
      begin
          connection = @db_conn_pool.get_connection()
          preparedStatement = connection.prepareStatement("INSERT INTO ProfileLookups(lookup_key, profile_id) VALUES (?, ?)")
          preparedStatement.setString(1, lookup_key)
          preparedStatement.setString(2, lookup_value)
          preparedStatement.executeUpdate()
          return true 
      rescue Exception => error
        puts "!! ERROR ADDING PROFILE LOOKUP!! -- #{error.message} -- #{error.backtrace}"
        return false 
      ensure    
        puts ""      
        puts "********** addProfileLookup - Before connection closed *********"
        @db_conn_pool.get_stats
        preparedStatement.close()
        connection.close()
        puts "********** addProfileLookup - Afters connection closed *********"
        @db_conn_pool.get_stats
      end  
    end


    def lookupProfile(lookup_key)
      begin 
          connection = @db_conn_pool.get_connection()
          preparedStatement = connection.prepareStatement("SELECT * FROM ProfileLookups WHERE lookup_key=?")  
          preparedStatement.setString(1, lookup_key)   
          resultSet = preparedStatement.executeQuery()

          if(!resultSet.isBeforeFirst())
            return false
          end

          while (resultSet.next()) 
            lookUpKey                            = resultSet.getString("lookup_key")
            profile_id                          = resultSet.getString("profile_id")
          end

          profile = ActiveSupport::HashWithIndifferentAccess.new({
            :lookup_key => lookUpKey,
            :profile_id => profile_id
          })  

      rescue Exception => error
        puts "!! ERROR LOOKING UP PROFILE !! -- #{error.message} -- #{error.backtrace}"
        return false 
      ensure  
        puts ""    
        puts "********** lookupProfile - Before connection closed *********"
        @db_conn_pool.get_stats
        resultSet.close()
        preparedStatement.close()
        connection.close()  
        puts "********** lookupProfile - Afters connection closed *********"
        @db_conn_pool.get_stats
      end  
    end
  end
end