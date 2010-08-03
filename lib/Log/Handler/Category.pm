=head1 NAME

Log::Handler::Category - Configuration examples for categories.

=head1 CONFIGURATION EXAMPLES

Note that you can find a full code example in the distribution within
the directory C<Log-Handler-$VERSION/examples/category/>.

=head2 example1.conf

    <file>
        filename log/common.log
        maxlevel info
        minlevel emerg
        message_layout %T [%L] (%p) %m
    </file>

    <category>
        <MyApp::Admin>
            <file>
                filename log/admin.log
                maxlevel info
                minlevel emerg
                message_layout %T [%L] (%p) %m
            </file>
        </MyApp>

        <MyApp::Admin::User>
            <file>
                filename log/user.log
                maxlevel info
                minlevel emerg
                message_layout %T [%L] (%p) %m
            </file>
        </MyApp::Admin::User>
    </category>

Load the configuration

    use Log::Handler;

    my $log = Log::Handler->new();
    $log->config("example1.conf");

Or with

    use Log::Handler;

    my $log = Log::Handler->config("example1.conf");

=head2 example2.conf

    <category>
        <main>
            <file>
                filename log/common.log
                maxlevel info
                minlevel emerg
                message_layout %T [%L] (%p) %m
            </file>
        </main>

        <MyApp::Admin>
            <file>
                filename log/admin.log
                maxlevel info
                minlevel emerg
                message_layout %T [%L] (%p) %m
            </file>
        </MyApp>

        <MyApp::Admin::User>
            <file>
                filename log/user.log
                maxlevel info
                minlevel emerg
                message_layout %T [%L] (%p) %m
            </file>
        </MyApp::Admin::User>
    </category>

Load the configuration

    package MyApp;
    use Log::Handler;

    Log::Handler->config("example2.conf");

    my $log = Log::Handler->get_logger("main");

=head2 example3.conf with aliases

Aliases are stricly recommended if you want to reload the
logging machine with C<reload>.

    <file>
        <common>
            filename log/common.log
            maxlevel info
            minlevel emerg
            message_layout %T [%L] (%p) %m
        </common>

        <error>
            filename log/error.log
            maxlevel warning
            minlevel emerg
            message_layout %T [%L] (%p) %m
        </error>
    </file>

    <category>
        <MyApp::Admin>
            <file>
                <common>
                    filename log/admin-common.log
                    maxlevel info
                    minlevel emerg
                    message_layout %T [%L] (%p) %m
                </common>

                <error>
                    filename log/admin-error.log
                    maxlevel warning
                    minlevel emerg
                    message_layout %T [%L] (%p) %m
                </error>
            </file>
        </MyApp>

        <MyApp::Admin::User>
            <file>
                alias    common
                filename log/user.log
                maxlevel info
                minlevel emerg
                message_layout %T [%L] (%p) %m
            </file>
        </MyApp::Admin::User>
    </category>

=head1 AUTHOR

Jonny Schulz <jschulz.cpan(at)bloonix.de>.

=cut
