package StackExchange::API;
#ABSTRACT: Very simple wrappers to the StackExchange API

use strict;
use 5.10.0;

=head1 DESCRIPTION

This is not a full programming library for the StackExchange API at
L<https://api.stackexchange.com/>, but just a set of methods to facilitate
access. Feel free to fork and extend to a full featured library!

=cut

use LWP::UserAgent;
use URI;
use HTTP::Message;
use JSON;

use Log::Contextual::WarnLogger;
use Log::Contextual qw(:log), -default_logger
    => Log::Contextual::WarnLogger->new({ env_prefix => __PACKAGE__ });

our $API_BASE = 'https://api.stackexchange.com/2.0/';

# initialize
sub new {
	my ($class,%args) = @_;

	$args{site} //= '';
	my $base = $API_BASE;
	my $ua   = LWP::UserAgent->new;
	$ua->default_header(
		'Accept-Encoding' => HTTP::Message::decodable
	);

	bless {
		site => $args{site},
		base => $base,
		ua   => $ua,
	}, $class;
}

# simple query
sub request {
	my ($self,$path,%query) = @_;

	$query{site} //= $self->{site} if defined $self->{site};

	my $url = URI->new($self->{base}.$path);
	$url->query_form( %query );
	
	log_info { $url };

	my $response = $self->{ua}->get($url)->decoded_content;
	log_trace { $response };

	my $json = from_json( $response );
	if ($json->{error_id}) {
		log_error { $json->{error_name} . ': ' . $json->{error_message} };
		return;
	}

	return $json;
}

# get paged results
sub request_all {
	my ($self,$path,%query) = @_;

	my @items = ();

	$query{page} = 1;
	$query{pagesize} //= 100;

	while(1) {
		my $result = $self->request($path, %query) || last;
		push @items, @{ $result->{items} } if $result->{items};
		last unless $result->{has_more};
		sleep ($result->{backoff} || 1);
		$query{page}++;
	}

	return \@items;
}


1;
