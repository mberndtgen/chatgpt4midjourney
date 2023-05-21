#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use JSON;
use OpenAI::API;

# Define variables to store the command line arguments
my $subject;
my $style;
my $template;
my $temperature;

my $openai = OpenAI::API->new();    # uses OPENAI_API_KEY environment variable

my $githubPath = "https://raw.githubusercontent.com/mberndtgen/chatgpt4midjourney/master/";

# Get the command line arguments
GetOptions(
    'subject=s'  => \$subject,
    'style=s'    => \$style,
    'template=s' => \$template,
    'temperature=f' => \$temperature
) or die("Error in command line arguments\n");

# Check that subject and template have been provided
if (!$subject || !$template) {
    die("Missing mandatory parameters. Usage: script.pl --subject <subject> --template <template> [--style <style>] [--temperature <temp>]\n");
}

$temperature = 0.2 if (!$temperature);

print "Subject: $subject\n";
print "Style: $style\n" if $style;
print "Template: $template\n";
print "Temperature: $temperature\n";

my $url = $githubPath . $template;
my $templateContent = slurp($url);

# Replace <subject> and <style> in the template content
$templateContent =~ s/<subject>/$subject/g;
$templateContent =~ s/<style>/($style || "") . " style"/ge;

# print "Modified Template Content:\n$templateContent\n";

my $gpt3_response = call_openai_api($templateContent);
print "Your prompt:\n" , $gpt3_response, "\n";


# Define the slurp function
sub slurp {
    my $url = shift;

    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);

    if ($response->is_success) {
        return $response->decoded_content;
    } else {
        die "Failed to get '$url': ", $response->status_line;
    }
}

sub call_openai_api {
    my ($prompt) = @_;
    
    my $res = $openai->chat(
        messages => [
            { "role" => "system", "content" => "You are an eloquent and literate poet." },
            { "role" => "user",   "content" => $prompt },
        ],
        max_tokens  => 250,
        temperature => $temperature + 0.0,
    );

    my $message = $res->{choices}[0]{message};
    return $message->{content};
}