require 'rubygems'
require 'watir-webdriver'
require 'headless'

class AWSInvoiceDownloader
	attr_reader :invoiceName, :invoiceLink, :invoicePath
	def initialize
		@download_directory = "#{Dir.pwd}/invoices"
		@invoicePath = "#{@download_directory}/invoice.pdf"
		if (!File.exists?(@download_directory))
			Dir.mkdir(@download_directory, 0755)
		end
		@mime_type = "application/pdf"
		@profile = firefox_profile
		@account = "xxxxxxx@domain.com"
		@password = "PASSWORD"
	end

	def firefox_profile
		profile = Selenium::WebDriver::Firefox::Profile.new
		profile['browser.download.folderList'] = 2 # custom location
		profile['browser.download.dir'] = @download_directory
		profile['browser.helperApps.neverAsk.saveToDisk'] = @mime_type
		return profile
	end

	def start
		Headless.ly do
			begin
				@browser = Watir::Browser.new :firefox, :profile => @profile
				if (File.exists?(@invoicePath))
					File.unlink(@invoicePath)
				end
			
				puts "Go to AWS Activity Summary Page"
				@browser.goto("https://portal.aws.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=activity-summary")
	
				if (@browser.title.match(/Amazon Web Services Sign In/))
					puts "Go to AWS Login Page"
					@browser.text_field(:id, "ap_email").set(@account)
					@browser.text_field(:id, "ap_password").set(@password)
					@browser.button(:src, /sign-in-secure/).click
		
					print "Login..."
					Watir::Wait.until {@browser.title.match(/^Amazon Web Services$/)}
					print "Done"
					puts ""
					@invoiceName = @browser.select_list(:name, "statementTimePeriod").options[1].text
					puts "Select The Latest Invoce: #{@invoiceName}"
					@browser.select_list(:name, "statementTimePeriod").options[1].select


					puts "Retrieve Invoice PDFs Link"
					Watir::Wait.until {
						@browser.link(:id, "toggle_ATVPDKIKX0DER_monthly").parent.span(:class, "txtxxsm").text.match(/View charges and download PDFs/)
					}
					puts @invoiceLink = @browser.link(:class, "invoiceLink").href
					@browser.goto @invoiceLink

					print "Downloading..."
					Watir::Wait.until {
						File.exists?(@invoicePath)
					}	
					print "done"
					puts
					
				end
			ensure
				@browser.close()
			end
		end
	end

end

downloader = AWSInvoiceDownloader.new
downloader.start
puts "done"
