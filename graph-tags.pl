#!/usr/bin/perl

use strict;
use 5.10.0;
use utf8;

use Log::Contextual::SimpleLogger;
use Log::Contextual qw( :log ),
	-logger => Log::Contextual::SimpleLogger->new({ levels_upto => 'info' });

use RDF::Trine;
use RDF::Trine::Model::StatementFilter;
use RDF::Trine::Exporter::GraphViz;
use RDF::NS '20120521';
use constant NS => RDF::NS->new('20120521');
use autodie;

my $site = (shift @ARGV) // '';
my $dir = "data/$site";
my $ttlfile = "$dir/tags-as-skos.ttl";
die "Usage: $0 <site> [-d]\n" unless $site =~ /^[a-z]+$/;
die "$ttlfile not found\n" unless -f $ttlfile;

my $debug = grep { /^-d/ } @ARGV;
my $model = RDF::Trine::Model::StatementFilter->new;
$model->add_rule( sub {
		return shift->predicate->uri =~
			qr{http://www.w3.org/2004/02/skos/core\#(narrower|related)};
	} );

my $parser = RDF::Trine::Parser->guess_parser_by_filename($ttlfile);
my $exporter = RDF::Trine::Exporter::GraphViz->new(
	style => { 
		rankdir => 'TB',
	},
	resource => {
		shape => 'ellipse'
	},
	alias => sub {
		return shift =~ qr{http://$site.stackexchange.com/tags/([^/]+)} 
			? $1 : '';
	},
	url => 1,
	graph => "$site.stackexchange",
	# requires a fix to RDF::Trine::Exporter::GraphViz!
	edge => sub { 
		return shift =~ /narrower/ ? 
			{ style => 'bold' } : { };
	}
);

$parser->parse_file_into_model ( "file://$ttlfile", $ttlfile, $model );

log_info { "$dir/tag-graph.svg" };
$exporter->serialize_model_to_file( "$dir/tag-graph.svg", $model );

