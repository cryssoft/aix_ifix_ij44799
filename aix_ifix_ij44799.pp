#
#  2023/03/27 - cp - Would you believe, so raw there's no advisory or packaging???
#
#  2023/03/27 - cp - Son of a...  This one applies to TL5/SP5 as well as VIOS
#		3.1.4.10...
#
#-------------------------------------------------------------------------------
#
class aix_ifix_ij44799 {

    #  Make sure we can get to the ::staging module (deprecated ?)
    include ::staging

    #  This only applies to AIX and maybe VIOS in later versions
    if ($::facts['osfamily'] == 'AIX') {

        #  Set the ifix ID up here to be used later in various names
        $ifixName = 'IJ44799'

        #  Make sure we create/manage the ifix staging directory
        require aix_file_opt_ifixes

        #
        #  For now, this one only impacts VIOS, but I don't know why.
        #
        if ($::facts['aix_vios']['is_vios']) {
            #
            #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
            #  suffix allready applied.
            #
            if ($::facts['aix_vios']['version'] in ['3.1.4.10']) {
                $ifixSuffix = 'm5a'
                $ifixBuildDate = '230218.VIOS3.1.4.10'
            }
            else {
                $ifixSuffix = 'unknown'
                $ifixBuildDate = 'unknown'
            }
        }
        else {
            #
            #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
            #  suffix allready applied.
            #
            if ($::facts['kernelrelease'] in ['7200-05-05-2246']) {
                $ifixSuffix = 'm5a'
                $ifixBuildDate = '230218.AIX72TL05SP05'
            }
            else {
                $ifixSuffix = 'unknown'
                $ifixBuildDate = 'unknown'
            }
        }

        #  Add the name and suffix to make something we can find in the fact
        $ifixFullName = "${ifixName}${ifixSuffix}"

        #  If we set our $ifixSuffix and $ifixBuildDate, we'll continue
        if (($ifixSuffix != 'unknown') and ($ifixBuildDate != 'unknown')) {

            #  Don't bother with this if it's already showing up installed
            unless ($ifixFullName in $::facts['aix_ifix']['hash'].keys) {
 
                #  Build up the complete name of the ifix staging source and target
                $ifixStagingSource = "puppet:///modules/aix_ifix_ij44799/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"
                $ifixStagingTarget = "/opt/ifixes/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"

                #  Stage it
                staging::file { "$ifixStagingSource" :
                    source  => "$ifixStagingSource",
                    target  => "$ifixStagingTarget",
                    before  => Exec["emgr-install-${ifixName}"],
                }

                #  GAG!  Use an exec resource to install it, since we have no other option yet
                exec { "emgr-install-${ifixName}":
                    path     => '/bin:/sbin:/usr/bin:/usr/sbin:/etc',
                    command  => "/usr/sbin/emgr -e $ifixStagingTarget",
                    unless   => "/usr/sbin/emgr -l -L $ifixFullName",
                }

                #  Explicitly define the dependency relationships between our resources
                File['/opt/ifixes']->Staging::File["$ifixStagingSource"]->Exec["emgr-install-${ifixName}"]

                #  Make sure we remove the old stuff first
                Class['aix_ifix_ij43869_remover']->Class['aix_ifix_ij44799']
            }

        }

    }

}
