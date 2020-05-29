import 'package:flutter/material.dart';
import 'package:seeds/models/models.dart';
import 'package:seeds/providers/services/http_service.dart';
import 'package:seeds/utils/invites.dart';
import 'package:seeds/widgets/clipboard_text_field.dart';
import 'package:seeds/widgets/main_button.dart';
import 'package:seeds/i18n/claim_code.i18n.dart';

enum ClaimCodeStatus {
  emptyInviteCode,
  searchingInvite,
  foundNoInvite,
  foundClaimedInvite,
  foundValidInvite,
  networkError,
}

class ClaimCode extends StatefulWidget {
  final String inviteCode;
  final Function onClaim;

  ClaimCode({this.inviteCode, this.onClaim});

  @override
  _ClaimCodeState createState() => _ClaimCodeState();
}

class _ClaimCodeState extends State<ClaimCode> {
  var inviteCodeController = TextEditingController();

  ClaimCodeStatus status = ClaimCodeStatus.emptyInviteCode;
  String claimedAccount;
  String inviterAccount;
  String inviteSecret;
  String inviteHash;
  String transferQuantity;
  String sowQuantity;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      if (widget.inviteCode != null) {
        inviteCodeController.text = widget.inviteCode;
      }
    });
    super.initState();
  }

  void findInvite() async {
    String inviteCode = inviteCodeController.text;

    if (inviteCode == "") {
      setState(() {
        status = ClaimCodeStatus.emptyInviteCode;
      });
      return;
    }

    setState(() {
      status = ClaimCodeStatus.searchingInvite;
    });

    inviteSecret = secretFromMnemonic(inviteCode);
    inviteHash = hashFromSecret(inviteSecret);

    InviteModel invite;

    try {
      invite = await HttpService.of(context).findInvite(inviteHash);

      if (invite.account == null || invite.account == '') {
        setState(() {
          status = ClaimCodeStatus.foundValidInvite;
          inviterAccount = invite.sponsor;
          transferQuantity = invite.transferQuantity;
          sowQuantity = invite.sowQuantity;
        });
      } else {
        setState(() {
          status = ClaimCodeStatus.foundClaimedInvite;
          inviterAccount = invite.sponsor;
          claimedAccount = invite.account;
        });
      }
    } on NetworkException {
      setState(() {
        status = ClaimCodeStatus.networkError;
      });
    } on EmptyResultException {
      setState(() {
        status = ClaimCodeStatus.foundNoInvite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 33),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ClipboardTextField(
            controller: inviteCodeController,
            labelText: "Invite code (5 words)".i18n,
            hintText: "Paste from clipboard".i18n,
            onChanged: findInvite,
          ),
          SizedBox(height: 16),
          status == ClaimCodeStatus.emptyInviteCode
              ? Center(
                  child: Text(
                    "If you received invite from another Seeds member - enter secret words and it will be claimed automatically".i18n,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "worksans",
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                )
              : Container(),
          status == ClaimCodeStatus.searchingInvite
              ? Center(
                  child: Column(
                    children: <Widget>[
                      CircularProgressIndicator(),
                      SizedBox(height: 5),
                      Text("Looking for invite...".i18n),
                    ],
                  ),
                )
              : Container(),
          status == ClaimCodeStatus.networkError
              ? Center(
                  child: Text("Network not available, try later".i18n),
                )
              : Container(),
          status == ClaimCodeStatus.foundNoInvite
              ? Center(
                  child: Text("No invites found, try another code".i18n),
                )
              : Container(),
          status == ClaimCodeStatus.foundClaimedInvite
              ? Center(
                  child: Text(
                    "Invite of %s was already claimed by %s".i18n.fill(["$inviterAccount", "$claimedAccount"]),
                  ),
                )
              : Container(),
          status == ClaimCodeStatus.foundValidInvite
              ? Column(
                  children: <Widget>[
                    Text(
                      "Congratulations! You are invited by %s - %s will be transferred and %s will be planted to your account - continue to create an account".i18n.fill(["$inviterAccount", "$transferQuantity", "$sowQuantity"]),
                    ),
                    MainButton(
                      title: 'Claim code'.i18n,
                      margin: EdgeInsets.only(top: 10),
                      onPressed: () => widget.onClaim(
                        inviteSecret: inviteSecret,
                        inviterAccount: inviterAccount,
                      ),
                    ),
                  ],
                )
              : Container(),
        ],
      ),
    );
  }
}
