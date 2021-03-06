use strict;
use warnings;
use Test::More;

use TAP::Parser;
use TAP::Parser::Source;
use TAP::Parser::Aggregator;

use TAP::Parser::SourceHandler::ForkingPerl;

my $class = 'TAP::Parser::SourceHandler::ForkingPerl';

{
    my $source = TAP::Parser::Source->new->raw(\'t/tests/foo.t');
    $source->assemble_meta;

    ok($class->can_handle($source) > 0.5, 'we handle .t files reasonably well');

    my $iter = $class->make_iterator($source);
    isa_ok($iter, 'TAP::Parser::Iterator::ForkedProcess');

    my @data;
    push @data, "$_\n" while $_ = $iter->next;
    is(join(q{}, @data), <<'EOT', "got test output, and it didn't inherit our test count");
ok 1 - foo
1..1
EOT

    is($iter->exit, 0, 'child exited successfully');
}

{
    my $source = TAP::Parser::Source->new->raw(\'t/tests/preloaded_module.t')->config({
        'ForkingPerl' => { preload => 'PreloadedModule' }
    });
    $source->assemble_meta;

    my $aggr = TAP::Parser::Aggregator->new;
    my $parser = TAP::Parser->new({ iterator => $class->make_iterator($source) });
    $parser->run;
    $aggr->add('t/tests/preloaded_module.t' => $parser);

    ok($aggr->all_passed, 'preload config preloaded the module');
}

done_testing;
